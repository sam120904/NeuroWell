import requests

TOKEN = "i_JgZo8gZtMMRLjmNpCfJDgzA7xayVCC"
BASE_URL = "https://blynk.cloud/external/api"

def check_pin(pin):
    url = f"{BASE_URL}/get?token={TOKEN}&pin={pin}"
    print(f"Checking {pin}: {url}")
    try:
        response = requests.get(url)
        print(f"Status: {response.status_code}")
        print(f"Body: {response.text}")
    except Exception as e:
        print(f"Error: {e}")
    print("-" * 20)

print("Testing Blynk API...")
check_pin("D0") # Normal Simulation
check_pin("D1") # Stress Simulation
# check_pin("V0") # Removed as invalid
# check_pin("V1") # Removed as invalid
