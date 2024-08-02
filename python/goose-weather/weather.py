import requests
GEOCODE_API_URL="https://geocode.maps.co"
class Coordinates:
    def __init__(self, zip_code:str=None, city:str=None, state:str=None):
        self.zip_code = zip_code
        self.city     = city
        self.state    = state
    
    def get_lat_lon(self, zip_code:str=None, city:str=None, state:str=None):
        """
        Return the coordinates and location based on a search.
        """
        response=requests.get(f"{GEOCODE_API_URL}/search?q={zip_code}+{city}+{state}+US",
                            timeout=10).json()
        lat=round(float(response[0]['lat']), 4)
        lon=round(float(response[0]['lon']), 4)
        locale=response[0]['display_name']
        return list(lat, lon, locale)

class Weather:
    def __init__(self, lat, lon):
        self.lat = lat
        self.lon = lon

coords = Coordinates(29642)
print(coords.get_lat_lon())
