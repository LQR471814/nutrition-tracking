from docling.datamodel.base_models import InputFormat
from docling.document_extractor import DocumentExtractor


extractor = DocumentExtractor(allowed_formats=[InputFormat.IMAGE, InputFormat.PDF])


def main():
    source = "https://www.ars.usda.gov/ARSUserFiles/80400525/Data/retn/retn06.pdf"
    result = extractor.extract(
        source=source,
        template="""{
            "retention_code": "int",
            "food_group_code": "int",
            "retention_description": "string",
            "calcium": "int",
            "iron": "int",
            "magnesium": "int",
            "phosphorus": "int",
            "potassium": "int",
            "sodium": "int",
            "zinc": "int",
            "copper": "int",
            "vitamin_c": "int",
            "thiamin": "int",
            "riboflavin": "int",
            "niacin": "int",
            "vitamin_b6": "int",
            "folate_food": "int",
            "folic_acid": "int",
            "folate_total": "int",
            "choline": "int",
            "vitamin_b12": "int",
            "vitamin_a_iu": "int",
            "vitamin_a_re": "int",
            "alcohol": "int",
            "carotene": "int",
            "cryptoxanthin_beta": "int",
            "lycopene": "int",
            "lutein_and_zeaxanthin": "int"
        }""",
    )
    print(result.pages)

if __name__ == "__main__":
    main()
