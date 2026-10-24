import re

from rest_framework import serializers

from .stock_ml import RANGE_DAYS

_TICKER = re.compile(r"^[A-Z0-9.\-^=&]{1,20}$")


class TickerSerializer(serializers.Serializer):
    ticker = serializers.CharField(max_length=20)

    def validate_ticker(self, value):
        value = value.strip().upper()
        if not _TICKER.match(value):
            raise serializers.ValidationError("Invalid ticker symbol, for example RELIANCE.NS or AAPL.")
        return value


class StockQuerySerializer(TickerSerializer):
    range = serializers.ChoiceField(choices=list(RANGE_DAYS), default="3M", required=False)