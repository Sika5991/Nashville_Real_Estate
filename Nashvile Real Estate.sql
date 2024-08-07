/* View the imported table */
SELECT *
FROM nashville_housing;

/* Create a new table 'nashville_housing_v0' by copying data from 'nashville_housing' for data cleaning purposes */
SELECT *
INTO nashville_housing_v0
FROM nashville_housing;

/* Since ParcelID does not change, replace null values in the PropertyAddress column with their appropriate address */
DROP TABLE nashville_housing_v0;


/* Update the 'PropertyAddress' column in 'nashville_housing_v0' by replacing null values with the corresponding address from rows with matching 'ParcelId' */
WITH PropertyAddress_CTE AS (
    SELECT a.*,
    ISNULL(b.PropertyAddress, a.PropertyAddress) AS NewPropertyAddress
    FROM nashville_housing a
    LEFT JOIN nashville_housing b 
        ON a.ParcelId = b.ParcelId
        AND a.UniqueId <> b.UniqueId
)
UPDATE t1
SET t1.PropertyAddress = t2.NewPropertyAddress
FROM nashville_housing_v0 t1
JOIN PropertyAddress_CTE t2
    ON t1.UniqueID = t2.UniqueID
;

/* Standardize the 'LandUse' values in 'nashville_housing_v0' by updating them to corrected or consistent values:
   - 'VACANT RES LAND' and 'VACANT RESIENTIAL LAND' are changed to 'VACANT RESIDENTIAL LAND'
   - 'GREENBELT/RES GRRENBELT/RES' is updated to 'GREENBELT'
   - All other values remain unchanged */
WITH LandUse_CTE AS (
    SELECT
    UniqueID,
    CASE 
        WHEN LandUse = 'VACANT RES LAND' THEN 'VACANT RESIDENTIAL LAND'
        WHEN LandUse = 'VACANT RESIENTIAL LAND' THEN 'VACANT RESIDENTIAL LAND'
        WHEN LandUse LIKE 'GREENBELT/RES%GRRENBELT/RES' THEN 'GREENBELT'
        ElSE LandUse
    END AS NewLandUse
    FROM nashville_housing_v0
)
UPDATE t1
SET t1.LandUse = t2.NewLandUse
FROM nashville_housing_v0 t1
INNER JOIN LandUse_CTE t2
    ON t1.UniqueID = t2.UniqueID
;

/* Convert the 'SoldAsVacant' values in 'nashville_housing_v0' to standardized format:
   - 'Y' is updated to 'Yes'
   - 'N' is updated to 'No'
   - All other values remain unchanged */
WITH SoldAsVacant_CTE AS (
    SELECT
    UniqueID,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END AS NewSoldAsVacant
    FROM nashville_housing_v0
)
UPDATE t1
SET t1.SoldAsVacant = t2.NewSoldAsVacant
FROM nashville_housing_v0 t1
INNER JOIN SoldAsVacant_CTE t2
    ON t1.UniqueID = t2.UniqueID
;

DROP TABLE nashville_housing_v1;

/* Clean and transform data from 'nashville_housing_v0' and create a new table 'nashville_housing_v1' with the following updates:
   - Remove '.00' from 'ParcelID'.
   - Extract the street address and city from 'PropertyAddress'.
   - Convert 'SalePrice' to integer.
   - Normalize 'SoldAsVacant' values to 0 (No) and 1 (Yes).
   - Split 'OwnerName' into two parts if it contains '&', otherwise retain as is.
   - Set 'DualOwnerFlag' to indicate the presence of dual owners.
   - Parse 'OwnerAddress' into street address, city, and state components.
   - Select other relevant fields as is.
   The transformed data is inserted into a new table 'nashville_housing_v1'. */
WITH nashville_cleanup_CTE AS (
    SELECT 
    UniqueID,
    REPLACE(ParcelID, '.00', '') AS ParcelID,
    LandUse,
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS PropertyAddress,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City,
    SaleDate,
    CAST(SalePrice AS INT) AS SalePrice,
    LegalReference,
        CASE 
            WHEN LTRIM(RTRIM(SoldAsVacant)) = 'No' THEN CAST('0' AS INT)
            WHEN LTRIM(RTRIM(SoldAsVacant)) = 'Yes' THEN CAST('1' AS INT)
        END AS SoldAsVacant,
    OwnerName,
        CASE 
            WHEN CHARINDEX('&', OwnerName) > 0 THEN SUBSTRING(OwnerName, 1, CHARINDEX('&', OwnerName)-1)
            ELSE OwnerName
        END AS OwnerName1,
        CASE 
            WHEN CHARINDEX('&', OwnerName) > 0 THEN SUBSTRING(OwnerName, CHARINDEX('&', OwnerName)+1, LEN(OwnerName)) 
            ELSE Null
        END AS OwnerName2,
        CASE
            WHEN CHARINDEX('&', OwnerName) > 0 THEN 1 
            WHEN CHARINDEX('&', OwnerName) = 0 THEN 0
            ELSE NULL
            END AS DualOwnerFlag,
    SUBSTRING(OwnerAddress,1, CHARINDEX(',', OwnerAddress) -1) AS OwnerStreetAddress,
    SUBSTRING(
        OwnerAddress, 
        CHARINDEX(',', OwnerAddress) + 2, 
        CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) +1) - CHARINDEX(',', OwnerAddress) - 2) 
        AS OwnerCity,
    SUBSTRING(
        OwnerAddress, 
        CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress)+1) +1,
        LEN(OwnerAddress) - (CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1))
     ) AS OwnerState,
    Acreage,
    TaxDistrict,
    LandValue,
    BuildingValue,
    TotalValue,
    YearBuilt,
    Bedrooms,
    FullBath,
    Halfbath
    FROM nashville_housing_v0
)
SELECT *
INTO nashville_housing_v1
FROM nashville_cleanup_CTE;
;

/*Remove dupliactes from the table */
DROP TABLE nashville_housing_v2;

/* Remove duplicate records from 'nashville_housing_v1' based on 'ParcelID', 'SaleDate', 'SalePrice', and 'LegalReference':
   - Assign a unique row number to each record within partitions of duplicate entries using the 'ROW_NUMBER()' function.
   - Keep only the first record (row_number = 1) for each set of duplicates.
   - Insert the cleaned data into a new table 'nashville_housing_v2'. */
WITH Duplicates_CTE AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference  ORDER BY UniqueID) AS row_number
    FROM nashville_housing_v1
)
SELECT *
INTO nashville_housing_v2
FROM Duplicates_CTE
WHERE row_number = 1
;

/* Remove unnecessary columns -- Dropping the TotalValue column because the value does not align with the land and building value*/

DROP TABLE nashville_housing_v3;

/* Create a new table 'nashville_housing_v3' from 'nashville_housing_v2' with only the necessary columns
   - This results in a streamlined dataset with relevant information for further analysis. */
SELECT 
    UniqueID,
    ParcelID,
    LandUse,
    PropertyAddress,
    City,
    SaleDate,
    SalePrice,
    SoldAsVacant,
    OwnerName1,
    OwnerName2, 
    DualOwnerFlag,
    OwnerStreetAddress,
    OwnerCity,
    OwnerState,
    Acreage,
    TaxDistrict,
    LandValue,
    BuildingValue,
    YearBuilt,
    Bedrooms,
    FullBath,
    HalfBath
INTO nashville_housing_v3
FROM nashville_housing_v2;

/* Review cleaned dataset */
SELECT *
FROM nashville_housing_v3;

/* What is the volume of unique values in the LandUse, City, OwnerCity, TaxDistrict */
SELECT DISTINCT 
City,
COUNT(*) AS Volume
FROM nashville_housing_v3
GROUP BY City
ORDER BY Volume Desc;

SELECT DISTINCT 
OwnerCity,
COUNT(*) AS Volume
FROM nashville_housing_v3
GROUP BY OwnerCity
ORDER BY Volume Desc;

SELECT DISTINCT 
TaxDistrict,
COUNT(*) AS Volume
FROM nashville_housing_v3
GROUP BY TaxDistrict
ORDER BY Volume Desc;

SELECT DISTINCT 
LandUse,
COUNT(*) AS Volume
FROM nashville_housing_v3
GROUP BY LandUse
ORDER BY Volume Desc;

/* What is the maximum, minimum and average value  of Acreage, LandValue, BuildingValue and YearBuilt*/
SELECT
MIN(Acreage) AS Min_Acreage,
MAX(Acreage) AS Max_Acreage,
ROUND(AVG(Acreage),2) AS Avg_Acreage
FROM nashville_housing_v3
;