# Nashville_Real_Estate

README: Nashville Real Estate Data Cleaning and Transformation

Overview
This SQL script is designed to clean and transform the Nashville real estate dataset. The following operations are performed:

Creating Working Copies: The original dataset (nashville_housing) is copied to a working table (nashville_housing_v0) for data cleaning.
Data Cleaning:
Address Normalization: Null values in the PropertyAddress column are filled based on ParcelID.
Standardizing Categorical Data: Correct inconsistencies in the LandUse and SoldAsVacant columns.
Transformations:
Removing unnecessary characters from ParcelID.
Extracting components from PropertyAddress and OwnerAddress.
Standardizing values in SoldAsVacant.
Splitting OwnerName into two parts and creating a DualOwnerFlag.
Creating Cleaned Dataset:
A new table (nashville_housing_v1) is created with the cleaned and transformed data.
Duplicate records are removed, and the result is stored in nashville_housing_v2.
Unnecessary columns are dropped, creating a streamlined dataset (nashville_housing_v3).
Data Review:
Summary statistics and distinct counts for various fields, including City, OwnerCity, TaxDistrict, and LandUse.
Calculations for minimum, maximum, and average values of Acreage, LandValue, BuildingValue, and YearBuilt.
