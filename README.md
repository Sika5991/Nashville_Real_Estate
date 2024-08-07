# Nashville_Real_Estate

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
  SELECT * FROM nashville_housing;

## Data Cleaning
### Normalizing PropertyAddress
Null values in the PropertyAddress column are filled based on matching ParcelID.

### Standardizing LandUse
- 'VACANT RES LAND' and 'VACANT RESIENTIAL LAND' are changed to 'VACANT RESIDENTIAL LAND'
- 'GREENBELT/RES GRRENBELT/RES' is updated to 'GREENBELT'

### Standardizing SoldAsVacant
Convert:
- 'Y' to 'Yes'
- 'N' to 'No'

## Data Transformation

## Data Review
