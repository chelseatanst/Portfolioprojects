-- Cleaning Data: Using Nashville Property Dataset

select *
from PortfolioProject..NashvilleHousing

-- Standardise Date format - Switch from DATETIME to DATE
select SaleDate, cast(saledate as date)
from PortfolioProject..NashvilleHousing



ALTER TABLE NashvilleHousing 
ADD SalesDate Date;
UPDATE NashvilleHousing
set SalesDate = CAST(SaleDate AS date)

-- Property address 
-- Notice that there are some Nulls in the PropertyAddress
select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is null

select *
from PortfolioProject..NashvilleHousing
--Upon further examination, ParcelID is NOT unique, and generally we observe that 
--some records with identical IDs have been populated with the same Property Address
-- while some of them have a NULL on the address.

-- Thus a join will be done to fill in the NULL addressses 
select a.[UniqueID ],a.ParcelID,a.PropertyAddress,b.[UniqueID ],b.ParcelID,b.PropertyAddress,ISNULL(a.propertyaddress,b.PropertyAddress) 
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
on a.ParcelID = b.ParcelID
--UNIQUE id have to be specified here because 
-- we're not joining on the exact same record but on another row 
--that is NULL and has a unique ID 
and a.[UniqueID ]<>b.[UniqueID ]

--update the table with the new column
update a
set propertyaddress=ISNULL(a.propertyaddress,b.propertyaddress)
from PortfolioProject..NashvilleHousing a join
PortfolioProject..NashvilleHousing b on 
a.ParcelID=b.ParcelID
where a.[UniqueID ]<>b.[UniqueID ]
and a.PropertyAddress is null

-----------------------------------------------------------------------------
-- We want to break out Address into Individual columns i.e. Address, City, State
--Using SUBSTRING
select propertyaddress
from PortfolioProject..NashvilleHousing

select
SUBSTRING(propertyaddress,1,CHARINDEX(',',propertyaddress)-1) as Address, --This is to separate the address from the city
substring(propertyaddress,CHARINDEX(',',propertyaddress)+1,LEN(propertyaddress)) as AddressCity --This is to extract city to a new column
from PortfolioProject..NashvilleHousing

--Using PARSENAME
SELECT PropertyAddress,
PARSENAME(REPLACE(PropertyAddress,',','.'),2),
PARSENAME(REPLACE(PropertyAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing

--Now that we found out this works, it's time to update the table
ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress nvarchar(255);
--These 2 chunks between have to be run separately for sql to digest that you're adding in new columns 
--before proceeding
UPDATE NashvilleHousing
set PropertySplitAddress = SUBSTRING(propertyaddress,1,CHARINDEX(',',propertyaddress)-1)

ALTER TABLE NashvilleHousing 
ADD PropertySplitCity nvarchar(255);
UPDATE NashvilleHousing
set PropertySplitCity = substring(propertyaddress,CHARINDEX(',',propertyaddress)+1,LEN(propertyaddress))

--Checking to see if the updates have been reflected on the main table
select *
from PortfolioProject..NashvilleHousing

-----------------------------------------------------------------------------
--OWNER Address clean up
select OwnerAddress
from PortfolioProject..NashvilleHousing


-- Using PARSENAME()
select OwnerAddress, PARSENAME(replace(owneraddress,',','.'),3),
PARSENAME(replace(owneraddress,',','.'),2),
PARSENAME(replace(owneraddress,',','.'),1)
from PortfolioProject..NashvilleHousing

--Using SUBSTRING() --GET BACK TO THIS
select OwnerAddress,
SUBSTRING(OwnerAddress,1,CHARINDEX(',',OwnerAddress)-1),
SUBSTRING(OwnerAddress,CHARINDEX(',',OwnerAddress)+1,CHARINDEX(', TN',OwnerAddress))
from PortfolioProject..NashvilleHousing

select OwnerAddress,CHARINDEX('TN',OwnerAddress)-4
from PortfolioProject..NashvilleHousing


--Updating it to the main table
ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress nvarchar(255);
UPDATE NashvilleHousing
set OwnerSplitAddress = PARSENAME(replace(owneraddress,',','.'),3)

ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity nvarchar(255);
UPDATE NashvilleHousing
set OwnerSplitCity = PARSENAME(replace(owneraddress,',','.'),2)

ALTER TABLE NashvilleHousing 
ADD OwnerSplitState nvarchar(255);
UPDATE NashvilleHousing
set OwnerSplitState = PARSENAME(replace(owneraddress,',','.'),1)

select *
from PortfolioProject..NashvilleHousing

-----------------------------------------------------------------------------

--Checking the 'SoldasVacant' column
select distinct(SoldAsVacant),COUNT(soldasvacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
--There are inconsistencies in a supposed binary column
-- We want to change it to Yes and Nos rather than Y or N

select SoldAsVacant,
case when soldasvacant = 'Y' then 'Yes'
	 when soldasvacant = 'N' then 'No'
	 else soldasvacant
	 end
from PortfolioProject..NashvilleHousing

--Update it to the main table
UPDATE NashvilleHousing
set SoldAsVacant= case when soldasvacant = 'Y' then 'Yes'
	 when soldasvacant = 'N' then 'No'
	 else soldasvacant
	 end

-----------------------------------------------------------------------------
-- Finding Duplicates and removing them
--Using ROW_NUMBER to identify duplicates
-- ROW_NUMBER assigns a sequential rank number to each new record in a partition you specify
-- Any duplicates would be flagged out as having a number more than 1
select *
from PortfolioProject..NashvilleHousing

select *,
(row_number() over(
partition by parcelid,
propertyaddress,
saledate,
saleprice,
legalreference
order by
parcelid) as row_num
from PortfolioProject..NashvilleHousing

--Creating a CTE to observe if there are duplicate records
with RowNumCTE as(
select *,
row_number() over(
partition by parcelid,
propertyaddress,
saledate,
saleprice,
legalreference
order by
uniqueid) row_num
from PortfolioProject..NashvilleHousing
)

/* select *
from rownumcte
where row_num>1 */

--There are 104 rows with duplicates, we want to delete them
delete
from rownumcte
where row_num>1

--To ensure those rows have been deleted off, we'll run the SELECT query again
with RowNumCTE as(
select *,
row_number() over(
partition by parcelid,
propertyaddress,
saledate,
saleprice,
legalreference
order by
uniqueid) row_num
from PortfolioProject..NashvilleHousing
)

select *
from rownumcte
where row_num>1

-----------------------------------------------------------------------------

--Delete unused columns (Not very common)
--We had some updated and cleaned columns from above
-- so we'll delete the unclean ones 
select *
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column owneraddress, taxdistrict,propertyaddress

alter table PortfolioProject..NashvilleHousing
drop column SaleDate