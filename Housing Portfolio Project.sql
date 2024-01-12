--CLEANING DATA IN SQL QUERIES

SELECT*
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------------------------------------------------------------------------------
--Changing the sale date into a standard format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

--This first quaery failed to convert the date into a shorter formayt that excludes the time 

ALTER TABLE [dbo].[NashvilleHousing]
Add SaleDateConverted Date;

UPDATE[dbo].[NashvilleHousing]
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------
--Populating the property address data 

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
--This returned some repeated parcel ID's. These had similar addresses hence the data in both rows can be joined

--Joining the table to itself 
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
--The UniqueID's are however unique to themselves 
	AND a.[UniqueID ] <> b.[UniqueID ]

--Using ISNULL() function to look out for NULL's in the property address column of the first table 'a' and replacing them the values of the property address column of the second table 'b'
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
--The UniqueID's are however unique to themselves 
	AND a.[UniqueID ] <> b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL

--updating the NULL values of propertyAddress column of the first table 'a' with the values of the propertyAdress column of the second table 'b'
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
--The UniqueID's are however unique to themselves 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
--After updating the column, return to the above select query to confirm no data is returned in the columns

------------------------------------------------------------------------------------------------------------------------------------------------
--Breaking out address into individual columns (address, city, state)


select PropertyAddress
from [dbo].[NashvilleHousing]


--Using a SUBSTRING() function to truncate the values/ strings in the PropertyAddress column to to exclude any strings after and before the comma
SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
from [dbo].[NashvilleHousing]

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1  ,LEN(PropertyAddress)) as Address

from [dbo].[NashvilleHousing]

--Creating two new columns in the table to accomodate this data 

ALTER TABLE [dbo].[NashvilleHousing]
Add PropertySplitAddress nvarchar(255);

UPDATE[dbo].[NashvilleHousing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE [dbo].[NashvilleHousing]
Add PropertySplitcity nvarchar(255);

UPDATE[dbo].[NashvilleHousing]
SET PropertySplitcity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1  ,LEN(PropertyAddress))


SELECT*
FROM PortfolioProject.dbo.NashvilleHousing

--An alternative column separator to use is the PARSENAME() function.
--PARSENAME() however separates things backwards
--We replace the commas with periods because PARSENAME() only reads periods and separates data from there 

select 
PARSENAME(REPLACE(OwnerAddress, ',','.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',','.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)
from NashvilleHousing 

ALTER TABLE [dbo].[NashvilleHousing]
Add OwnerSplitAddress nvarchar(255);

UPDATE[dbo].[NashvilleHousing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)

ALTER TABLE [dbo].[NashvilleHousing]
Add OwnerSplitcity nvarchar(255);

UPDATE[dbo].[NashvilleHousing]
SET OwnerSplitcity = PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)

ALTER TABLE [dbo].[NashvilleHousing]
Add OwnerSplitState nvarchar(255);

UPDATE[dbo].[NashvilleHousing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)

----------------------------------------------------------------------------------------------------------------------------------

--CHANGE Y AND N TO YES AND NO IN "SOLD AND VACANT" FIELD

select Distinct (SoldAsVacant)
from NashvilleHousing
--Looking out for distinct or different values from the SoldAsVacant table

select Distinct (SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant,

CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
	END 
from NashvilleHousing

UPDATE[dbo].[NashvilleHousing]
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
	END 
from NashvilleHousing

-------------------------------------------------------------------------------------------------------------------------------------------

--REMOVE DUPLICATES

--Using the ROW_NUMBER() window function to assign sequential integers to each row in the result set.
--Using the PARTITION BY clause to divide the result set by ParcelID, PropertyAddress, SalePrice, SaleDate and LegalReference
--The ORDER BY  clause sorts the owner in each PropertyAddress, SalePrice, SaleDate, legalReference by UniqueID
--Using a CTE to perfrom a function on the created row_num column

with RowNumCTE as(
SELECT*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
					UniqueID
				)row_num
			
FROM NashvilleHousing
--ORDER BY ParcelID
)

select*
from RowNumCTE
where row_num > 1
order by PropertyAddress 

------------------------------------------------------------------------------------------------------------------------------------------------------------

--DELETE UNUSED COLUMNS

SELECT*
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate