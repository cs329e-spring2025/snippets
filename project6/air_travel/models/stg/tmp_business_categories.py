import json
import vertexai
from vertexai.generative_models import GenerativeModel
from google.cloud import bigquery

region = "us-central1"
model_name = "gemini-2.0-flash-001"
prompt = """Go through the list of categories and look for categories that have similar meanings and have differences in spelling and naming.
For example, 'Airline Ticket Counters' and 'Airline Ticketing' have similar meanings and 'Mother Room and 'Mother's Room' have similar meanings.
Suggest a standard category, mapping the current one to the new one.
Return the list of original categories along with their new categories.
Format the results as a json object with the schema: current_category:string, new_category:string.
Do not include any unchanged categories with your answer.
Do not include an explanation with your answer.
"""

def model(dbt, session):
    
    category_sql = "select distinct category from air_travel_raw.airport_businesses" 
    bq_client = bigquery.Client()
    rows = bq_client.query_and_wait(category_sql)

    category_list = []
    for row in rows:
        category_list.append(row["category"])
    category_str = "\n".join(category_list)
    #print("category_str:", category_str)

    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([category_str, prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("resp_text:", resp_text)
    
    categories = json.loads(resp_text)
    
    replacements = {} # will store the new categories

    # categories can be either a dictionary or list type (depending on what LLM decides to do!)
    if type(categories) == dict:
        for old, new in categories.items():
            if old == new:
                continue
            else:
                replacements[old] = new

    if type(categories) == list:
        for cat_entry in categories:
            if cat_entry['current_category'] == cat_entry['new_category']:
                continue
            else:
                replacements[cat_entry['current_category']] = cat_entry['new_category']

    print("replacements:", replacements)

    # read the source table 
    businesses_df = dbt.source("air_travel_raw", "airport_businesses")
    
    # merge the new categories using pyspark's replace()
    # https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.DataFrame.replace.html
    output_df = businesses_df.na.replace(replacements, "category")
    
    return output_df