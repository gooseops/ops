#TO DO:
# Add tests
# Validate api response before sending it to client
# Add retry on apis if validation fails
# Add error handling in api calls
#Grow to geolocation class and weather classes
#Pass class objects around
#Database cache for geocoords
#Abstract base class for geolocation
#Caching geolocation extension
import os
"""
Module for serving Flask App
"""
from datetime import datetime
import requests
from flask import Flask, render_template, request

GEOCODE_API_URL="https://geocode.maps.co"
GEOCODE_API_KEY=os.environ['GEOCODE_API_KEY']
WEATHER_API_URL="https://api.weather.gov"

app = Flask(__name__)

def get_lat_lon(zip_code:str=None, city:str=None, state:str=None):
    """
    Return the coordinates and location based on a search.
    """
    response=requests.get(f"{GEOCODE_API_URL}/search?q={zip_code}+{city}+{state}+US&api_key={GEOCODE_API_KEY}",
                          timeout=10).json()
    lat=round(float(response[0]['lat']), 4)
    lon=round(float(response[0]['lon']), 4)
    locale=response[0]['display_name']
    return lat, lon, locale

def get_forecast_api_urls(lat:str, lon:str):
    """
    Return the api urls for different typse of forecasts.
    """
    response=requests.get(f"{WEATHER_API_URL}/points/{lat},{lon}", timeout=10).json()
    return response

def get_daily_forecast(zip_code:str=None, city:str=None, state:str=None):
    """
    Return a daily forecast for the upcoming week.
    """
    lat, lon, locale=get_lat_lon(zip_code, city, state)
    fc_api_urls=get_forecast_api_urls(lat, lon)
    daily_fc=requests.get(f"{fc_api_urls['properties']['forecast']}", timeout=10).json()
    return lat, lon, locale, daily_fc

def get_hourly_forecast(zip_code:str=None, city:str=None, state:str=None):
    """
    Return a hourly forecast for the upcoming 12 hours.
    """
    lat, lon, locale=get_lat_lon(zip_code, city, state)
    fc_api_urls=get_forecast_api_urls(lat, lon)
    hourly_fc=requests.get(f"{fc_api_urls['properties']['forecastHourly']}", timeout=10).json()
    return lat, lon, locale, hourly_fc

@app.context_processor
def utility_processor():
    """
    Return a dictionary of template available functions.
    """
    def format_time(dt_iso):
        """
        Return a 12 hour formatted time.
        """
        t=datetime.strptime(dt_iso, "%Y-%m-%dT%H:%M:%S%z")
        t_12hour=t.strftime("%I:%M %p")
        return t_12hour
    return {"format_time": format_time}

@app.route('/')
def index():
    """
    Render Home Page
    """
    return render_template('index.html')

@app.route('/weather', methods = ['POST', 'GET'])
def weather():
    """
    Render Weather form or page.
    """
    if request.method == 'GET':
        return render_template('weather-form.html')
    if request.method == 'POST':
        options=request.form.getlist('frequency')
        zip_code=request.form['zip_code']
        city=request.form['city']
        state=request.form['state']
        if options[0] == 'current':
            lat, lon, locale, forecast=get_hourly_forecast(zip_code, city, state)
            return render_template('hourly-weather.html',
                                lat=lat,
                                lon=lon,
                                locale=locale,
                                forecasts=forecast['properties']['periods'][slice(0, 1, 1)]
                                )
        if options[0] == 'daily':
            lat, lon, locale, forecast=get_daily_forecast(zip_code, city, state)
            return render_template('daily-weather.html',
                                lat=lat,
                                lon=lon,
                                locale=locale,
                                forecasts=forecast['properties']['periods']
                                )
        if options[0] == 'hourly':
            lat, lon, locale, forecast=get_hourly_forecast(zip_code, city, state)
            return render_template('hourly-weather.html',
                                lat=lat,
                                lon=lon,
                                locale=locale,
                                forecasts=forecast['properties']['periods'][slice(0, 12, 1)]
                                )
        return None
    return None
