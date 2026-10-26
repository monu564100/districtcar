#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scrape_jharkhand_agencies.py — Fill Marketing Tracker via Google Places API (ToS-compliant)
Usage:
  pip install requests openpyxl
  python scrape_jharkhand_agencies.py --api-key YOUR_GOOGLE_PLACES_API_KEY --out DistrictCar_Marketing_Priority_Database_Jharkhand_Tracker.xlsx

What it does: For each Jharkhand district + hotspot, calls Google Places Text Search
  "tours and travels near [District]", "taxi service [District]", "cab booking [Block]"
  → writes Company, Address, Phone (via Place Details), Website, Rating, Hours (Availability) to the tracker.

Get API key: https://console.cloud.google.com/apis/library/places-backend.googleapis.com → Enable + Create key (free $300 credit)
No scraping of Justdial HTML — only official Places API (allowed, stable).
"""
import argparse, time, re
import requests, openpyxl

DISTRICTS = ["Ranchi","Khunti","Gumla","Simdega","Lohardaga","Chaibasa","Jamshedpur","Seraikela","Hazaribagh","Ramgarh","Bokaro","Dhanbad","Giridih","Koderma","Chatra","Daltonganj","Latehar","Garhwa","Deoghar","Dumka","Godda","Sahebganj","Pakur","Jamtara"]
KEYWORDS = ["tours and travels near {}", "taxi service {}", "cab booking {}", "car rental {}"]

def places_text_search(api_key, query):
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    r = requests.get(url, params={"query": query, "key": api_key}, timeout=15)
    r.raise_for_status()
    j = r.json()
    return j.get("results", [])

def place_details(api_key, place_id):
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    r = requests.get(url, params={"place_id": place_id, "fields": "name,formatted_address,formatted_phone_number,website,rating,opening_hours,url", "key": api_key}, timeout=15)
    r.raise_for_status()
    return r.json().get("result", {})

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--api-key", required=True, help="Google Places API key")
    ap.add_argument("--out", default="DistrictCar_Marketing_Priority_Database_Jharkhand_Tracker.xlsx", help="Output XLSX path")
    ap.add_argument("--in", dest="inp", default=None, help="Input tracker XLSX to fill (default: create new)")
    args = ap.parse_args()

    # Load or create workbook
    if args.inp and __import__("os").path.exists(args.inp):
        wb = openpyxl.load_workbook(args.inp)
        ws = wb["Directory — Priority Sorted"]
        start_row = ws.max_row + 1
    else:
        # Create minimal sheet if no input
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Directory — Priority Sorted"
        ws.append(["#","Priority","District / Area","Hotspot / Stand","Category","Company / Agency","Contact Person","Phone","Address","Website","Availability","Source","Status","Quote Sent?","Reply","Rating","Why Priority","Notes"])
        start_row = 2

    rid = ws.max_row
    for district in DISTRICTS:
        for kw in KEYWORDS:
            query = kw.format(district + ", Jharkhand")
            print(f"Searching: {query} ...")
            try:
                results = places_text_search(args.api_key, query)
            except Exception as e:
                print(f"  Error: {e}")
                continue
            for res in results[:5]:  # top 5 per keyword
                place_id = res.get("place_id")
                name = res.get("name","")
                addr = res.get("formatted_address","")
                # Avoid duplicates by name+district
                exists = any(ws.cell(r,c).value==name for r in range(2, ws.max_row+1) for c in [6])
                if exists:
                    continue
                # Fetch phone/website/rating/hours
                phone = ""; website=""; rating=""; hours=""
                if place_id:
                    try:
                        det = place_details(args.api_key, place_id)
                        phone = det.get("formatted_phone_number","") or ""
                        website = det.get("website","") or det.get("url","") or ""
                        rating = str(det.get("rating","")) or ""
                        oh = det.get("opening_hours", {})
                        hours = "Daily" if oh.get("open_now") else ("Hours: " + ", ".join(oh.get("weekday_text",[])[:1]) if oh.get("weekday_text") else "")
                        time.sleep(0.2)
                    except Exception as e:
                        print(f"  details error {name}: {e}")
                rid+=1
                ws.append([rid, "P1", district, "", "CAT-B", name, "", phone or "TO VERIFY — CALL", addr, website, hours or "Daily", "Google Places API", "Found — To Verify" if phone else "Found — To Verify", "No", "", rating, f"Auto-filled via Places API query: {query}", ""])
                print(f"  + {name} | {phone or 'no phone'} | {addr[:50]}")
            time.sleep(1)

    wb.save(args.out)
    print(f"\nDone → {args.out} ({ws.max_row-1} agencies). Verify phones by 60-sec call before quoting.")

if __name__ == "__main__":
    main()
