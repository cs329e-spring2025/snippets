import json
import vertexai
from vertexai.generative_models import GenerativeModel, Part

region = "us-central1"
model_name = "gemini-2.0-flash-001"
prompt = """Find a match for each country that I pass you based on the 256 reference countries.
For example, if I pass you the country 'Syrian Arab Republic', map it to 'Syria'.
If there is no good match, default to null
Format your answer as a dictionary, with the schema: {current<string>: new<string>}.
For example, {"Syrian Arab Republic": "Syria", "Swaziland": null}
The reference countries are: \n
"""

def model(dbt, session):
    reference_df = dbt.ref("Country").select("name").to_string(header=False)
    orphans_df = dbt.ref("tmp_countries_orphan").to_string(header=False)

    prompt += reference_df
    print("prompt:", prompt)

    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([orphans_df, prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("results_raw:", resp_text)
    replacements = json.loads(resp_text)
    print("replacements:", replacements)

    airlines_df = dbt.ref("airlines")
    airlines_df["country"] = airlines_df["country"].map(replacements)
    print("updated airlines df")
    print("airlines_df:", airlines_df.head(5))

    return airlines_df