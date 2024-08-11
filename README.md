# Nashville Real Estate Data Cleaning and Transformation

## Overview
This repository contains SQL scripts for cleaning and transforming the Nashville real estate dataset. The dataset includes various property details, and this script standardizes and prepares the data for analysis.

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Data Cleaning](#data-cleaning)
3. [Data Transformation](#data-transformation)
4. [Data Review](#data-review)

## Initial Setup
- **Viewing the Original Data**:
  ```sql
  SELECT * FROM nashville_housing_v0;

## Data Cleaning
### Normalizing PropertyAddress
Null values in the PropertyAddress column are filled based on matching ParcelID.
```sql
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
    ON t1.UniqueID = t2.UniqueID;
```

### Standardizing LandUse
- 'VACANT RES LAND' and 'VACANT RESIENTIAL LAND' are changed to 'VACANT RESIDENTIAL LAND'
- 'GREENBELT/RES GRRENBELT/RES' is updated to 'GREENBELT'
``` sql
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
      ON t1.UniqueID = t2.UniqueID;
```

### Standardizing SoldAsVacant
Convert:
- 'Y' to 'Yes'
- 'N' to 'No'
``` sql
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
      ON t1.UniqueID = t2.UniqueID;
```

## Data Transformation
### Creating nashville_housing_v1
Transformations Include:
- Removing '.00' from ParcelID.
- Extracting street address and city from PropertyAddress.
- Converting SalePrice to an integer.
- Normalizing SoldAsVacant values.
- Splitting OwnerName into two parts where applicable.
- Setting DualOwnerFlag based on the presence of dual owners.
- Parsing OwnerAddress into street address, city, and state.
``` sql
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
```

### Removing Duplicates
Creating nashville_housing_v2:
- Removing duplicates based on ParcelID, SaleDate, SalePrice, and LegalReference.
``` sql
    WITH Duplicates_CTE AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference  ORDER BY UniqueID) AS row_number
    FROM nashville_housing_v1
)
SELECT *
INTO nashville_housing_v2
FROM Duplicates_CTE
WHERE row_number = 1;
```

### Final Cleaned Dataset
Creating nashville_housing_v3:
- Selecting only necessary columns for streamlined analysis.
``` sql
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
```

## Data Review
### Volume of Unique Values
- **Counting unique values in City, OwnerCity, TaxDistrict, and LandUse**:
  ```sql
  SELECT DISTINCT City, COUNT(*) AS Volume
  FROM nashville_housing_v3
  GROUP BY City
  ORDER BY Volume DESC;

# Contributing
Feel free to open issues or submit pull requests if you have any suggestions or improvements.
