import argparse
import json
import urllib.request
import urllib.parse
import sys

def get_weather(city, api_key, units='metric', lang='zh_cn'):
    base_url = "http://api.openweathermap.org/data/2.5/forecast"
    params = {
        'q': city,
        'appid': api_key,
        'units': units,
        'lang': lang
    }
    
    url = f"{base_url}?{urllib.parse.urlencode(params)}"
    
    try:
        with urllib.request.urlopen(url) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                return data
            else:
                return {"error": f"HTTP Error: {response.status}"}
    except urllib.error.URLError as e:
        return {"error": f"Network Error: {e}"}
    except Exception as e:
        return {"error": f"Unknown Error: {e}"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch weather data using OpenWeatherMap API.")
    parser.add_argument("city", help="City name (e.g., Beijing)")
    parser.add_argument("api_key", help="OpenWeatherMap API Key")
    parser.add_argument("--units", default="metric", help="Units (metric/imperial)")
    parser.add_argument("--lang", default="zh_cn", help="Language code")
    
    args = parser.parse_args()
    
    result = get_weather(args.city, args.api_key, args.units, args.lang)
    print(json.dumps(result, ensure_ascii=False, indent=2))
