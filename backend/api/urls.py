from django.urls import path,include
from accounts import views as UserViews
from rest_framework_simplejwt.views import TokenObtainPairView,TokenRefreshView
from .stock_views import StockModelInfoView, StockPredictView, StockTodayView

urlpatterns=[
    path('register/',UserViews.RegisterView.as_view()),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    path('stock/predict/', StockPredictView.as_view(), name='stock-predict'),
    path('stock/today/', StockTodayView.as_view(), name='stock-today'),
    path('stock/model-info/', StockModelInfoView.as_view(), name='stock-model-info'),
]