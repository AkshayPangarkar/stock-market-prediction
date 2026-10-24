from rest_framework.response import Response
from rest_framework.views import APIView

from . import stock_ml as ml
from .stock_serializers import StockQuerySerializer, TickerSerializer


def _respond(fn, *args):
    """Run a payload builder and turn our errors into proper HTTP status codes."""
    try:
        return Response(fn(*args))
    except ml.StockApiError as e:
        return Response({"status": "error", "error": str(e)}, status=e.status_code)


class StockPredictView(APIView):
    """GET /stock/predict/?ticker=RELIANCE.NS&range=3M   (range: 1M, 3M, 6M, 1Y, All)

    Daily candles with the model's predicted close for each day, today's cards
    (current / predicted next close / difference) and an accuracy block.
    Permissions follow your DRF defaults (REST_FRAMEWORK in settings.py).
    """

    def get(self, request):
        q = StockQuerySerializer(data=request.query_params)
        q.is_valid(raise_exception=True)
        return _respond(ml.build_daily_payload, q.validated_data["ticker"], q.validated_data.get("range", "3M"))


class StockTodayView(APIView):
    """GET /stock/today/?ticker=RELIANCE.NS

    The latest session as 5-minute candles, each with a forecast of the next
    daily close. Poll it every 30 to 60 seconds for a live view.
    """

    def get(self, request):
        q = TickerSerializer(data=request.query_params)
        q.is_valid(raise_exception=True)
        return _respond(ml.build_today_payload, q.validated_data["ticker"])


class StockModelInfoView(APIView):
    """GET /stock/model-info/  - is the model file in place, and what does it expect."""

    def get(self, request):
        return Response(ml.model_info())