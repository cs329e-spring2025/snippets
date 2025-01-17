# pip install hurry.filesize
import requests, csv, os, datetime
from hurry.filesize import size
from pathlib import Path
from google.cloud import storage
from google.cloud.storage import transfer_manager

# Sunday to Saturday, start from 08/03/24 and go back in time
# should look like this: 
# https://www.tsa.gov/sites/default/files/foia-readingroom/tsa-total-throughput-data-july-28-2024-to-august-3-2024-1.pdf
# https://www.tsa.gov/sites/default/files/foia-readingroom/tsa-total-throughput-data-july-21-2024-to-july-27-2024.pdf
# https://www.tsa.gov/sites/default/files/foia-readingroom/tsa-total-throughput-data-july-7-2024-to-july-13-2024-1.pdf
# https://www.tsa.gov/sites/default/files/foia-readingroom/tsa-total-throughput-data-july-7-2024-to-july-13-2024.pdf

local_folder = "landing_zone/" # where to store the pdfs once downloaded
bucket_name = "tsa-traffic" # where to copy the pdfs to 
gcs_folder = "raw/" # where to copy the pdfs to 
url_prefix = 'https://www.tsa.gov/sites/default/files/foia-readingroom/tsa-total-throughput-data'

def main():
    
    end_date = 'august-3-2024' # the last date for which the report is available from tsa.gov
    date_format = '%B-%d-%Y'
    index = 1
    
    while True:
    
        index = index + 1
        print('index:', index)
        
        start_date_raw = datetime.datetime.strptime(end_date, date_format) - datetime.timedelta(days=6)
        start_date = start_date_raw.strftime(date_format).lower()

        start_date_parts = start_date.split('-')
        start_month = start_date_parts[0]
        start_day = start_date_parts[1]
        start_year = start_date_parts[2]
        
        # remove leading 0 in the day if applicable
        if start_day[0:1] == '0':
            start_day = start_day[1:]
            start_date = f"{start_month}-{start_day}-{start_year}" 
        
        url = f"{url_prefix}-{start_date}-to-{end_date}.pdf"
        print('url:', url) 
        
        filename = f"{local_folder}/{start_date}-to-{end_date}.pdf"
        
        status = download_document(url, filename)
        
        if status == False:
            print(f'download failed for {url}')
            break
            
        end_date_raw = start_date_raw - datetime.timedelta(days=1)
        end_date = end_date_raw.strftime(date_format).lower()
        
        
def download_document(url, filename):
    
    headers={'user-agent': 'Mozilla/5.0'}
    
    try:
        r = requests.get(url, headers=headers)

        with open(filename, 'wb') as file:
            file.write(r.content)
            print(f"wrote {filename}")
            filesize_kb = file.tell() / 1000
            filesize_mb = size(file.tell())
            
            if filesize_kb < 45:
                # file is < 5K, too small to be a valid map 
                os.remove(filename)
                print(f"deleted {filename} ({filesize_mb})")
                
                if url.split('.pdf')[0][-1] == '1':
                    return False
                else:
                    file_preffix = url.split('.pdf')[0]
                    url = f"{file_preffix}-1.pdf"
                    download_document(url, filename)
            else:    
                return True
            
    except Exception as e:
        print("Error:", e)


def copy_to_GCS():
    
    directory_as_path_obj = Path(local_folder)
    file_paths = directory_as_path_obj.rglob("*.pdf")
    relative_paths = [path.relative_to(local_folder) for path in file_paths]
    string_paths = [str(path) for path in relative_paths]
    print("Found {} files.".format(string_paths))
    
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    results = transfer_manager.upload_many_from_filenames(bucket, string_paths, source_directory=local_folder, blob_name_prefix=gcs_folder, max_workers=5)

    for name, result in zip(string_paths, results):
        if isinstance(result, Exception):
            print("Failed to upload {} due to exception: {}".format(name, result))
        else:
            print("Uploaded {} to {}.".format(name, bucket.name))
        

if __name__ == "__main__":
    #main()
    copy_to_GCS()