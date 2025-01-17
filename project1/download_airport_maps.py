# pip install hurry.filesize
import requests, csv, os
from hurry.filesize import size

def main():
    url_prefix = 'https://www.airport.guide/pdf/terminals/guides/k'

    with open('airport_codes.csv', mode='r') as file:
        csv_file = csv.reader(file)
        for i, line in enumerate(csv_file):
            if i == 0:
                continue
            airport = line[0]
            #print(airport)
            
            for terminal in range(1, 5):
                url = f"{url_prefix}{airport}/{airport}-terminal-{terminal}.pdf"
                #print(url)
                status = download_map(airport, terminal, url)
                if status == False:
                    # if there is not a terminal 1, move on to the next airport
                    break

def download_map(airport, terminal, url):
    
    headers={'user-agent': 'Mozilla/5.0'}
    
    try:
        r = requests.get(url, headers=headers)
        filename = f"maps/{airport}-terminal-{terminal}.pdf"
        with open(filename, 'wb') as file:
            file.write(r.content)
            print(f"wrote {filename}")
            filesize_kb = file.tell() / 1000
            filesize_mb = size(file.tell())
            if filesize_kb < 45:
                # file is < 45K, it's probably too small to be a valid map 
                os.remove(filename)
                print(f"deleted {filename} ({filesize_mb})")
                return False
            return True
            
    except Exception as e:
        print("Error:", e)
        

if __name__ == "__main__":
    main()