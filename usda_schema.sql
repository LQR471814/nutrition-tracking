-- 1. Base Lookup Tables (No dependencies)
CREATE TABLE food_category (
    id INTEGER PRIMARY KEY,
    code INTEGER,
    description TEXT
);

CREATE TABLE nutrient (
    id INTEGER PRIMARY KEY,
    "name" TEXT,
    unit_name TEXT,
    nutrient_nbr REAL,
    rank REAL
);

CREATE TABLE food_nutrient_source (
	id INTEGER PRIMARY KEY,
	code INTEGER,
	description TEXT NOT NULL
);

CREATE TABLE food_nutrient_derivation (
    id INTEGER PRIMARY KEY,
    code INTEGER,
    description TEXT
);

CREATE TABLE food_attribute_type (
    id INTEGER PRIMARY KEY,
    "name" TEXT,
    description TEXT
);

CREATE TABLE measure_unit (
    id INTEGER PRIMARY KEY,
    "name" TEXT
);

CREATE TABLE lab_method (
    id INTEGER PRIMARY KEY,
    description TEXT,
    technique TEXT
);

CREATE TABLE wweia_food_category (
    wweia_food_category INTEGER PRIMARY KEY,
    wweia_food_category_description TEXT
);

-- 2. Main Food Table
CREATE TABLE food (
    fdc_id INTEGER PRIMARY KEY,
    data_type TEXT,
    description TEXT,
    food_category_id INTEGER, -- Changed to INTEGER to match category(id)
    publication_date TEXT,
    FOREIGN KEY (food_category_id) REFERENCES food_category (id)
);

-- 3. Primary Dependent Tables
CREATE TABLE food_nutrient_conversion_factor (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE market_acquisition (
    fdc_id INTEGER PRIMARY KEY,
    brand_description TEXT,
    expiration_date TEXT,
    label_weight TEXT,
    "location" TEXT,
    acquisition_date TEXT,
    sales_type TEXT,
    sample_lot_nbr TEXT,
    sell_by_date TEXT,
    store_city TEXT,
    store_name TEXT,
    store_state TEXT,
    upc_code TEXT,
    acquisition_number TEXT,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE sample_food (
    fdc_id INTEGER PRIMARY KEY,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

-- 4. Secondary Dependent Tables (Referencing food, nutrients, or factors)
CREATE TABLE branded_food (
    fdc_id INTEGER PRIMARY KEY,
    brand_owner TEXT,
    brand_name TEXT,
    subbrand_name TEXT,
    gtin_upc TEXT,
    ingredients TEXT,
    not_a_significant_source_of TEXT,
    serving_size REAL,
    serving_size_unit TEXT,
    household_serving_fulltext TEXT,
    branded_food_category TEXT,
    data_source TEXT,
    package_weight TEXT,
    modified_date TEXT,
    available_date TEXT,
    market_country TEXT,
    discontinued_date TEXT,
    preparation_state_code TEXT,
    trade_channel TEXT,
    short_description TEXT,
    material_code INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE food_nutrient (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    nutrient_id INTEGER,
    amount REAL,
    data_points INTEGER,
    derivation_id INTEGER,
    min REAL,
    max REAL,
    median REAL,
    loq REAL,
    footnote TEXT,
    min_year_acquired INTEGER,
    percent_daily_value REAL,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id),
    FOREIGN KEY (nutrient_id) REFERENCES nutrient (id),
    FOREIGN KEY (derivation_id) REFERENCES food_nutrient_derivation (id)
);

CREATE TABLE food_attribute (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    seq_num INTEGER,
    food_attribute_type_id INTEGER,
    "name" TEXT,
    "value" TEXT,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id),
    FOREIGN KEY (food_attribute_type_id) REFERENCES food_attribute_type (id)
);

CREATE TABLE food_portion (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    seq_num INTEGER,
    amount REAL,
    measure_unit_id INTEGER,
    portion_description TEXT,
    modifier TEXT,
    gram_weight REAL,
    data_points INTEGER,
    footnote TEXT,
    min_year_acquired INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id),
    FOREIGN KEY (measure_unit_id) REFERENCES measure_unit (id)
);

CREATE TABLE food_calorie_conversion_factor (
    food_nutrient_conversion_factor_id INTEGER PRIMARY KEY,
    protein_value REAL,
    fat_value REAL,
    carbohydrate_value REAL,
    FOREIGN KEY (food_nutrient_conversion_factor_id) REFERENCES food_nutrient_conversion_factor (id)
);

CREATE TABLE food_protein_conversion_factor (
    food_nutrient_conversion_factor_id INTEGER PRIMARY KEY,
    "value" REAL,
    FOREIGN KEY (food_nutrient_conversion_factor_id) REFERENCES food_nutrient_conversion_factor (id)
);

CREATE TABLE foundation_food (
    fdc_id INTEGER PRIMARY KEY,
    NDB_number INTEGER,
    footnote TEXT,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE input_food (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    fdc_id_of_input_food INTEGER, -- Changed to INTEGER to match food(fdc_id)
    seq_num INTEGER,
    amount REAL,
    sr_code INTEGER,
    sr_description TEXT,
    unit TEXT,
    portion_code INTEGER,
    portion_description TEXT,
    gram_weight REAL,
    retention_code INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id),
    FOREIGN KEY (fdc_id_of_input_food) REFERENCES food (fdc_id)
);

CREATE TABLE sr_legacy_food (
    fdc_id INTEGER PRIMARY KEY,
    NDB_number INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE survey_fndds_food (
    fdc_id INTEGER PRIMARY KEY,
    food_code INTEGER,
    wweia_category_code INTEGER,
    start_date TEXT,
    end_date TEXT,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

-- 5. Specialized Samples and Results
CREATE TABLE acquisition_samples (
    fdc_id_of_sample_food INTEGER,
    fdc_id_of_acquisition_food INTEGER,
    FOREIGN KEY (fdc_id_of_sample_food) REFERENCES sample_food (fdc_id),
    FOREIGN KEY (fdc_id_of_acquisition_food) REFERENCES market_acquisition (fdc_id)
);

CREATE TABLE sub_sample_food (
    fdc_id INTEGER PRIMARY KEY,
    fdc_id_of_sample_food INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id),
    FOREIGN KEY (fdc_id_of_sample_food) REFERENCES food (fdc_id)
);

CREATE TABLE sub_sample_result (
    food_nutrient_id INTEGER PRIMARY KEY,
    adjusted_amount REAL,
    lab_method_id INTEGER,
    nutrient_name TEXT,
    FOREIGN KEY (food_nutrient_id) REFERENCES nutrient (id),
    FOREIGN KEY (lab_method_id) REFERENCES lab_method (id)
);

CREATE TABLE lab_method_code (
    lab_method_id INTEGER,
    code TEXT,
    FOREIGN KEY (lab_method_id) REFERENCES lab_method (id)
);

CREATE TABLE lab_method_nutrient (
    lab_method_id INTEGER,
    nutrient_id INTEGER,
    FOREIGN KEY (lab_method_id) REFERENCES lab_method (id),
    FOREIGN KEY (nutrient_id) REFERENCES nutrient (id)
);

-- 6. Remaining Support Tables
CREATE TABLE food_component (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER,
    "name" TEXT,
    pct_weight REAL,
    is_refuse TEXT,
    gram_weight REAL,
    data_points INTEGER,
    min_year_acquired INTEGER,
    FOREIGN KEY (fdc_id) REFERENCES food (fdc_id)
);

CREATE TABLE agricultural_samples (
    fdc_id INTEGER PRIMARY KEY,
    acquisition_date TEXT,
    market_class TEXT,
    treatment TEXT,
    state TEXT
);

CREATE TABLE fndds_derivation (
    "derivation code" TEXT PRIMARY KEY,
    "derivation description" TEXT
);

CREATE TABLE fndds_ingredient_nutrient_value (
    "ingredient code" INTEGER,
    "Ingredient description" TEXT,
    "Nutrient code" INTEGER,
    "Nutrient value" REAL,
    "Nutrient value source" TEXT,
    "FDC ID" INTEGER,
    "Derivation code" TEXT,
    "SR AddMod year" INTEGER,
    "Foundation year acquired" INTEGER,
    "Start date" TEXT,
    "End date" TEXT
);

CREATE TABLE microbe (
    id INTEGER PRIMARY KEY,
    foodId INTEGER,
    "method" TEXT,
    microbe_code TEXT,
    min_value INTEGER,
    max_value TEXT,
    uom TEXT
);

CREATE TABLE retention_factor (
    "n.gid" INTEGER PRIMARY KEY,
    "n.code" INTEGER NOT NULL,
    "n.foodGroupId" INTEGER,
    "n.description" TEXT
);

CREATE TABLE food_update_log_entry (
    id INTEGER PRIMARY KEY,
    description TEXT,
    last_updated TEXT
);

CREATE TABLE nutrient_requirement_map (
	requirement TEXT NOT NULL,
	nutrient_id INTEGER,
	FOREIGN KEY (nutrient_id) REFERENCES nutrient(id)
);

CREATE TABLE retention_factor_value (
	retention_code INTEGER PRIMARY KEY,
	food_group_code INTEGER NOT NULL,
	retention_description TEXT NOT NULL,
	calcium_ca INTEGER,
	iron_fe INTEGER,
	magnesium_mg INTEGER,
	phosphorus_p INTEGER,
	potassium_k INTEGER,
	sodium_na INTEGER,
	zinc_zn INTEGER,
	copper_cu INTEGER,
	vitamin_c_total_ascorbic_acid INTEGER,
	thiamin INTEGER,
	riboflavin INTEGER,
	niacin INTEGER,
	vitamin_b6 INTEGER,
	folate_food INTEGER,
	folic_acid INTEGER,
	folate_total INTEGER,
	choline_total INTEGER,
	vitamin_b12 INTEGER,
	vitamin_a_iu INTEGER,
	vitamin_a_re INTEGER,
	alcohol_ethyl INTEGER,
	carotene_beta INTEGER,
	carotene_alpha INTEGER,
	cryptoxanthin_beta INTEGER,
	lycopene INTEGER,
	lutein_zeaxanthin INTEGER,
	FOREIGN KEY (retention_code) REFERENCES retention_factor("n.code")
);
