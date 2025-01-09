
mysql --local-infile=1 -u username -p

#Create database
CREATE DATABASE IMPC;
USE IMPC;
#Create table
CREATE TABLE disease_table(
 disease_id VARCHAR(255),
 disease_term VARCHAR(255),
 gene_accession_id VARCHAR (255),
 phenodigm_score FLOAT,
 PRIMARY KEY (disease_id, gene_accession_id)
 );
 
CREATE TABLE parameter_table(
 impcParameterOrigId VARCHAR(255) PRIMARY KEY, 
 name VARCHAR(255),
 desccription TEXT,
 parameter_id VARCHAR(255)
);

CREATE TABLE procedure_table (
    procedure_id VARCHAR(255) PRIMARY KEY,        
    name VARCHAR(255) ,                 
    description TEXT,                           
    isMandatory BOOLEAN,          
    impcParameterOrigId VARCHAR(255),                  
    FOREIGN KEY (impcParameterOrigId) REFERENCES parameter_table(impcParameterOrigId)
);

CREATE TABLE analysis_table (
	analysis_id VARCHAR(255) PRIMARY KEY,
 	gene_accession_id VARCHAR (255),
 	gene_symbol VARCHAR(255),
 	mouse_strain VARCHAR(255),
	mouse_life_strge VARCHAR (255),
 	parameter_id VARCHAR(255),
 	parameter_name VARCHAR(255),
 	pvalue FLOAT,
 	group_name VARCHAR(255)
 	);
#upload data
 
LOAD DATA INFILE 'E:\\sql\\Uploads\\final_combined_cleaned_ID_data2.csv'
INTO TABLE Analysis
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, gene_symbol, mouse_strain, mouse_life_stage, parameter_id, parameter_name, pvalue, phenotype_group);

LOAD DATA LOCAL INFILE 'E:\\sql\\Uploads\\Disease_information_cleaned1025.csv'
INTO TABLE disease
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(disease_id, disease_term, gene_accession_id, phenodigm_score);


LOAD DATA LOCAL INFILE 'E:\\sql\\Uploads\\IMPC_parameter_description_cleaned1225'
INTO TABLE parameter
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(impcParameterOrigId, name, description, parameterId);

LOAD DATA LOCAL INFILE 'E:\\sql\\Uploads\\IMPC_parameter_description_cleaned1225'
INTO TABLE procedure
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(procedureID, name, description, isMandatory, impcParameterOrigId);


select *from analysis_table;
#Lists all the tables in the database
SHOW TABLES FROM impc;
#Determine which table contains genetic information
DESCRIBE impc.analysis_table;

DESCRIBE impc.disease_table;

DESCRIBE impc.parameter_table;

DESCRIBE impc.procedure_table;

#Search gene
SELECT 
    a.analysis_id,
    a.gene_accession_id,
    a.gene_symbol,
    a.mouse_strain,
    a.mouse_life_stage,
    a.parameter_id,
    a.parameter_name,
    a.pvalue,
    g.`group`,  -- from group_table get group column
    d.disease_id,
    d.disease_term,
    d.phenodigm_score,
    p.name AS parameter_description,
    pr.name AS procedure_name
FROM impc.analysis_table a
LEFT JOIN impc.disease_table d ON a.gene_accession_id = d.gene_accession_id
LEFT JOIN impc.parameter_table p ON a.parameter_id = p.parameter_id
LEFT JOIN impc.procedure_table pr ON p.impcParameterOrigId = pr.impcParameterOrigId
LEFT JOIN impc.group_table g ON a.parameter_name = g.parameter_name  -- 新增连接 group_table
WHERE a.gene_symbol IN ('Prelp', 'Proser2', 'Erich2', 'Romo1');


#Delete the group column of the analysis_table and create a new group table
ALTER TABLE impc.analysis_table
DROP COLUMN `group`;

DESCRIBE impc.analysis_table;

CREATE TABLE group_table (
    parameter_name VARCHAR(255) PRIMARY KEY,
    `group` VARCHAR(255)
);

#Ensure that the group_table contains the corresponding parameter_name value
SELECT DISTINCT parameter_name
FROM impc.analysis_table
WHERE parameter_name NOT IN (SELECT parameter_name FROM impc.group_table);


#Import CSV file to group_table in cmd 
LOAD DATA LOCAL INFILE 'E:\\sql\\Uploads\\parameter_groups.csv'
INTO TABLE impc.group_table
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
(parameter_name, `group`);

ALTER TABLE impc.analysis_table
ADD CONSTRAINT fk_parameter_name
FOREIGN KEY (parameter_name) 
REFERENCES impc.group_table(parameter_name)
ON DELETE CASCADE
ON UPDATE CASCADE;

#update data
#Disable foreign key check
SET foreign_key_checks = 0;

#delete original data
TRUNCATE TABLE impc.parameter_table;

#updata new data
LOAD DATA LOCAL INFILE 'E:\\sql\\Uploads\\IMPC_parameter_description_cleaned1228.csv'
REPLACE INTO TABLE impc.parameter_table
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
(parameter_id, name, description);

#Restore foreign key constraints
ALTER TABLE impc.procedure_table
ADD CONSTRAINT procedure_table_ibfk_1
FOREIGN KEY (parameter_name)
REFERENCES impc.parameter_table(parameter_name)
ON DELETE CASCADE
ON UPDATE CASCADE;


