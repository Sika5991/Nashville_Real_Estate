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

### Standardizing LandUse
- 'VACANT RES LAND' and 'VACANT RESIENTIAL LAND' are changed to 'VACANT RESIDENTIAL LAND'
- 'GREENBELT/RES GRRENBELT/RES' is updated to 'GREENBELT'

### Standardizing SoldAsVacant
Convert:
- 'Y' to 'Yes'
- 'N' to 'No'

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

### Removing Duplicates
Creating nashville_housing_v2:
- Removing duplicates based on ParcelID, SaleDate, SalePrice, and LegalReference.

### Final Cleaned Dataset
Creating nashville_housing_v3:
- Selecting only necessary columns for streamlined analysis.
- 
## Data Review
### Volume of Unique Values
- **Counting unique values in City, OwnerCity, TaxDistrict, and LandUse**:
  ```sql
  SELECT DISTINCT City, COUNT(*) AS Volume
  FROM nashville_housing_v3
  GROUP BY City
  ORDER BY Volume DESC;

# License
This project is licensed under the MIT License - see the LICENSE file for details.

# Contributing
Feel free to open issues or submit pull requests if you have any suggestions or improvements.

