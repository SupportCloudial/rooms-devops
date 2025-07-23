import getMonthlyPayments from "@salesforce/apex/OpportunityService.getMonthlyPayments";
import { onError, subscribe, unsubscribe } from "lightning/empApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord } from "lightning/uiRecordApi";
import { api, LightningElement, track, wire } from "lwc";

import applyFilter_btn from "@salesforce/label/c.rooms_applyFilter_btn";
import area_label from "@salesforce/label/c.rooms_area_label";
import desk_btnGrp from "@salesforce/label/c.rooms_desk_btnGrp";
import endMonth_label from "@salesforce/label/c.rooms_endMonth_label";
import endYear_label from "@salesforce/label/c.rooms_endYear_label";
import filtersCategory_Date from "@salesforce/label/c.rooms_filtersCategory_Date";
import filtersCategory_location from "@salesforce/label/c.rooms_filtersCategory_location";
import filtersCategory_Product from "@salesforce/label/c.rooms_filtersCategory_Product";
import helpTextLocation from "@salesforce/label/c.rooms_forecast_helpText_location";
import locationDisplay from "@salesforce/label/c.rooms_forecast_locationDisplay";
import location_label from "@salesforce/label/c.rooms_forecast_locationFilter";
import segmentationDisplay from "@salesforce/label/c.rooms_forecast_segmentationDisplay";
import product_label from "@salesforce/label/c.rooms_product_label";
import productFamilies_label from "@salesforce/label/c.rooms_productFamilies_label";
import productSubType_label from "@salesforce/label/c.rooms_productSubType_label";
import productType_label from "@salesforce/label/c.rooms_productType_label";
import shekel_btnGrp from "@salesforce/label/c.rooms_shekel_btnGrp";
import startMonth_label from "@salesforce/label/c.rooms_startMonth_label";
import startYear_label from "@salesforce/label/c.rooms_startYear_label";
import Product from "@salesforce/schema/Product2";
import Subtype from "@salesforce/schema/Product2.Sub_Type__c";
import ProductType from "@salesforce/schema/Product2.Type__c";

const DefaultProductType = "Standard Products";

export default class MonthlyPaymentFilters extends NavigationMixin(
  LightningElement
) {
  @track monthlyPayments = [];
  @track filteredMonthlyPayments = [];
  @track grandTotal = 0;
  @track filters = {};
  @api recordId;
  startMonth;
  startYear;
  endMonth;
  endYear;
  productSelectedFilter;
  areaSelectedFilter;
  locationSelectedFilter;
  productFamilySelectedFilter;
  productSubTypeSelectedFilter;
  startMonthFilter;
  startYearFilter;
  endMonthFilter;
  globalFinalPriceForProductSelected;
  endYearFilter;
  yearToApplyDiscount;
  monthlyPaymentsForReset;
  years = [];
  productFamilies = [];
  months = [];
  products = [];
  areas = [];
  locations = [];
  yearsDate = [];
  monthsDate = [];
  productsDate = [];
  applyMultipleDiscount = false;
  isYear = true;
  isAreaDisabled = false;
  isLocationDisabled = false;
  ordinateFormat = "totalFinalPrice";
  forecastDisplay = "segmentation";

  customLabels = {
    startMonth_label,
    startYear_label,
    endMonth_label,
    endYear_label,
    product_label,
    area_label,
    location_label,
    productFamilies_label,
    productType_label,
    productSubType_label,
    applyFilter_btn,
    desk_btnGrp,
    shekel_btnGrp,
    filtersCategory_Date,
    filtersCategory_location,
    filtersCategory_Product,
    segmentationDisplay,
    locationDisplay,
    helpTextLocation
  };

  subscription = {};
  channelName = "/event/MonthlyPaymentAdded__e";

  globalDiscount = "";

  optionsOrdinate = [
    { label: this.customLabels.shekel_btnGrp, value: "totalFinalPrice" },
    { label: this.customLabels.desk_btnGrp, value: "deskNumber" }
  ];

  forecastDisplayOptions = [
    { label: this.customLabels.segmentationDisplay, value: "segmentation" },
    { label: this.customLabels.locationDisplay, value: "location" }
  ];

  objectApiName;
  productTypeSelectedFilter = DefaultProductType;

  @wire(getObjectInfo, { objectApiName: Product })
  ProductObject;

  @wire(getPicklistValues, {
    recordTypeId: "$ProductObject.data.defaultRecordTypeId",
    fieldApiName: ProductType
  })
  productTypeOptionsWire({ data, error }) {
    if (data) {
      const allOption = {
        attributes: null,
        label: "All Types",
        validFor: [],
        value: "All"
      };
      this.productTypeOptions = [...data.values, allOption];
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$ProductObject.data.defaultRecordTypeId",
    fieldApiName: Subtype
  })
  productSubTypes;

  @wire(getRecord, {
    recordId: "$recordId",
    layoutTypes: ["Full"],
    modes: ["View"]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.objectApiName = data.apiName;
    } else if (error) {
      console.error("Error fetching record:", error);
    }
  }

  get productSubTypeOptions() {
    if (
      this.productSubTypes &&
      this.productSubTypes.data &&
      this.productTypeSelectedFilter
    ) {
      return this.setDependentPicklist(
        this.productSubTypes.data,
        this.productTypeSelectedFilter
      );
    }
  }

  setDependentPicklist(data, controllerValue) {
    const key = data.controllerValues[controllerValue];
    return data.values.filter((opt) => opt.validFor.includes(key));
  }

  connectedCallback() {
    this.handleSubscribe();
    this.getData();
  }
  mapLocationNameToId = new Map();

  // Loads monthly payment data and populates filter options when the component is first loaded
  getData() {
    let data;
    getMonthlyPayments({ oppId: null, contractId: null }).then((result) => {
      if (result) {
        data = result;
        this.monthlyPayments = this.transformData(data);
        console.log(
          "$$monthlyPayments = ",
          JSON.stringify(this.monthlyPayments)
        );

        this.monthlyPaymentsForReset = [
          ...JSON.parse(JSON.stringify(this.monthlyPayments))
        ];
        this.monthlyPaymentsForResetFilter = this.monthlyPayments;
        this.filteredMonthlyPayments = this.monthlyPayments;

        data.map((item) => {
          this.mapLocationNameToId.set(item.Products_Name__c, item.Room__c);
        });
        this.generateComboboxOptions(this.monthlyPayments, false);
      }
    });
  }

  handleOrdinateChange(event) {
    this.ordinateFormat = event.target.value;
    this.dispatchEvent(
      new CustomEvent("ordinateformatchange", { detail: event.target.value })
    );
  }
  handleDisplayChange(event) {
    this.forecastDisplay = event.target.value;
    this.dispatchEvent(
      new CustomEvent("forecastdisplaychange", { detail: event.target.value })
    );
  }

  // Subscribes to the platform event `MonthlyPaymentAdded__e` to refresh data when new monthly payments are added
  handleSubscribe() {
    const messageCallback = (response) => {
      this.getData();
    };

    subscribe(this.channelName, -1, messageCallback).then((response) => {
      this.subscription = response;
    });

    onError((error) => {
      console.error("Occurred an Error: ", JSON.stringify(error));
    });
  }

  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  handleUnsubscribe() {
    unsubscribe(this.subscription, (response) => {});
  }

  handleKeyDown(event) {
    const { month, year, room } = event.target.dataset;
    const monthYearData = this.monthlyPayments.filter(
      (item) => item.month == month && item.year == year
    );
    if (monthYearData.length === 0) {
      return null;
    }
    const roomData = monthYearData[0].data.filter((item) => item.room === room);
    if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      const increment = event.key === "ArrowUp" ? 1 : -1;
      if (event.target.name === "finalPrice") {
        roomData[0].finalPrice =
          (parseInt(event.target.value, 10) || 0) + increment;
        roomData[0].discount =
          100 - (100 * roomData[0].finalPrice) / roomData[0].listPrice;
        roomData[0].discount =
          roomData[0].discount % 1 != 0
            ? (Math.round(roomData[0].discount * 100) / 100).toFixed(2)
            : roomData[0].discount;
      } else {
        roomData[0].discount =
          (parseFloat(event.target.value) || 0) + increment;
        roomData[0].finalPrice =
          roomData[0].listPrice -
          (roomData[0].listPrice * roomData[0].discount) / 100;
      }
    }
  }

  handleFiltersChange(e) {
    this[e.target.name] =
      e.target.value == "All" ||
      e.target.name == "productSelectedFilter" ||
      e.target.name == "areaSelectedFilter" ||
      e.target.name == "locationSelectedFilter" ||
      e.target.name == "productFamilySelectedFilter" ||
      e.target.name == "productSubTypeSelectedFilter" ||
      e.target.name == "productTypeSelectedFilter"
        ? e.target.value
        : parseInt(e.target.value);

    const fieldName = e.target.name;
    const fieldValue = e.target.value;

    this.filters = {
      ...this.filters,
      [fieldName]: fieldValue
    };

    this.resetDependantSelect(e);

    console.log("$$filters = ", JSON.stringify(this.filters));
  }

  handleAreaFilter(e) {
    this.handleFiltersChange(e);
    if (e.target.name === "areaSelectedFilter") {
      this.isLocationDisabled = true;
    } else {
      this.isAreaDisabled = true;
    }

    if (
      Array.isArray(this.filters["locationSelectedFilter"]) &&
      this.filters["locationSelectedFilter"].length === 0
    ) {
      this.isAreaDisabled = false;
    }
  }

  resetDependantSelect(e) {
    if (e.target.name == "productTypeSelectedFilter") {
      if ("productSubTypeSelectedFilter" in this.filters) {
        delete this.filters["productSubTypeSelectedFilter"];
      }
    }
  }

  // Generates options for comboboxes (e.g., products, months, years) based on data
  generateComboboxOptions(data, isAfterFilter) {
    const sets = {
      products: new Set(),
      months: new Set(),
      years: new Set(),
      areas: new Set(),
      locations: new Set(),
      productFamilies: new Set(),
      productsFilter: new Set(),
      monthsFilter: new Set(),
      yearsFilter: new Set()
    };

    const populateSets = (entry, isFilter = false) => {
      sets.months.add(entry.month);
      sets.years.add(entry.year);
      entry.data.forEach((item) => {
        sets.products.add(item.room);
        sets.areas.add(item.area);
        sets.locations.add(item.location);
        sets.productFamilies.add(item.productFamily);
      });
      if (isFilter) {
        sets.monthsFilter.add(entry.month);
        sets.yearsFilter.add(entry.year);
        entry.data.forEach((item) => {
          sets.productsFilter.add(item.room);
        });
      }
    };

    // Populate sets from data
    data.forEach((entry) => populateSets(entry));
    this.monthlyPayments.forEach((entry) => populateSets(entry, true));

    // Helper function to generate combobox options
    const generateOptions = (set, labelSuffix = "") => {
      const options = Array.from(set)
        .filter((value) => value !== null && value !== "" && value != undefined)
        .map((value) => ({ label: value, value }));

      if (labelSuffix)
        options.push({ label: `All ${labelSuffix}`, value: "All" });

      return options;
    };

    if (!isAfterFilter) {
      this.products = generateOptions(sets.products, "products");
      this.areas = generateOptions(sets.areas, "areas");
      this.locations = generateOptions(sets.locations, "locations");
      this.productFamilies = generateOptions(sets.productFamilies, "families");
      this.months = generateOptions(sets.months).sort(
        (a, b) => a.value - b.value
      );
      this.years = generateOptions(sets.years);
    }

    this.productsDate = !isAfterFilter
      ? [...this.products]
      : generateOptions(sets.products);
    this.monthsDate = generateOptions(sets.months).sort(
      (a, b) => a.value - b.value
    );
    this.yearsDate = !isAfterFilter
      ? [...this.years]
      : generateOptions(sets.years);
  }

  get rooms() {
    const roomSet = new Set();
    this.filteredMonthlyPayments.forEach((monthData) => {
      monthData.data.forEach((data) => {
        roomSet.add(data.room);
      });
    });
    return Array.from(roomSet);
  }
  sumTotalPrice = 0;
  get dataByRoom() {
    this.sumTotalPrice = 0;
    const data = this.rooms.map((room) => {
      return {
        room: room,
        values: this.filteredMonthlyPayments.map((monthData) => {
          const roomData = monthData.data.find((data) => data.room === room);
          return {
            month: monthData.month,
            year: monthData.year,
            listPrice: roomData ? roomData.listPrice : "",
            discount: roomData ? roomData.discount : "",
            finalPrice: roomData ? roomData.finalPrice : ""
          };
        })
      };
    });

    for (let i = 0; i < data.length; i++) {
      let sum = data[i].values.reduce((accumulator, currentValue) => {
        let price = parseFloat(currentValue.finalPrice);
        return accumulator + (isNaN(price) ? 0 : price);
      }, 0);

      data[i].values.unshift({
        Total: sum % 1 === 0 ? parseInt(sum) : parseFloat(sum.toFixed(2))
      });
      this.sumTotalPrice += data[i].values[0].Total;
    }
    return data;
  }
  get totalsByMonth() {
    let dataTotal = this.filteredMonthlyPayments.map((monthData) => {
      let totalListPrice = monthData.data.reduce(
        (sum, data) => sum + data.listPrice,
        0
      );
      totalListPrice =
        totalListPrice % 1 != 0
          ? parseFloat(totalListPrice).toFixed(2)
          : parseInt(totalListPrice);
      const weightedDiscountSum = monthData.data.reduce(
        (sum, item) => sum + item.listPrice * item.discount,
        0
      );
      let totalFinalPrice = monthData.data.reduce(
        (sum, data) => sum + data.finalPrice,
        0
      );
      totalFinalPrice =
        totalFinalPrice % 1 != 0
          ? parseFloat(totalFinalPrice.toFixed(2))
          : totalFinalPrice;
      let totalDiscount = weightedDiscountSum / totalListPrice;
      totalDiscount =
        totalDiscount % 1 != 0
          ? parseFloat(totalDiscount.toFixed(2))
          : totalDiscount;
      return {
        month: monthData.month,
        year: monthData.year,
        totalListPrice,
        totalDiscount,
        totalFinalPrice
      };
    });
    dataTotal.unshift(this.sumTotalPrice);
    return dataTotal;
  }

  isExpanded = true;
  isFiltersExpanded = true;
  get iconNameToggle() {
    return this.isExpanded ? "utility:chevronup" : "utility:chevrondown";
  }
  get iconNameFiltersToggle() {
    return this.isFiltersExpanded ? "utility:chevronup" : "utility:chevrondown";
  }
  get containerClass() {
    return this.isExpanded ? "container expanded card" : "container card ";
  }
  get containerFiltersClass() {
    return this.isFiltersExpanded
      ? "container expanded card"
      : "container card ";
  }

  handleToggle(e) {
    e.target.name == "discount"
      ? (this.isExpanded = !this.isExpanded)
      : (this.isFiltersExpanded = !this.isFiltersExpanded);
  }

  // Groups the raw monthly payment data by month and year, calculates totals, and transforms data into a structured format
  transformData(data) {
    const groupedData = {};
    data.forEach((payment) => {
      const startdate = new Date(payment.Start_date__c);
      const month = startdate.getMonth() + 1;
      const year = startdate.getFullYear();
      const key = `${month}-${year}`;

      if (!groupedData[key]) {
        groupedData[key] = {
          month,
          year,
          data: [],
          total: 0
        };
      }

      groupedData[key].data.push({
        id: payment.Id,
        room: payment.Products_Name__c,
        listPrice: payment.price__c,
        area:
          payment.Location__r && payment.Location__r.Area__c
            ? payment.Location__r.Area__c
            : "",
        location:
          payment.Location__r && payment.Location__r.Name
            ? payment.Location__r.Name
            : "",
        discount: payment.Discount__c || 0,
        productSubType: payment.Room__r.Sub_Type__c,
        productType: payment.Room__r.Type__c,
        productFamily: payment.Room__r.Family,
        finalPrice:
          payment.price__c -
          (payment.price__c * (payment.Discount__c || 0)) / 100
      });
      groupedData[key].total +=
        payment.price__c -
        (payment.price__c * (payment.Discount__c || 0)) / 100;
    });

    return Object.values(groupedData);
  }

  resetTable() {
    this.filteredMonthlyPayments = this.monthlyPayments;
    this.generateComboboxOptions(this.monthlyPayments, false);
  }
  resetFilters() {
    this.resetSelectedFilterValues();
    this.generateComboboxOptions(this.monthlyPayments, false);
  }

  validate() {
    let isValid = true;
    let fields = this.template.querySelectorAll("lightning-combobox");
    fields.forEach((field) => {
      if (!field.checkValidity()) {
        field.reportValidity();
        isValid = false;
      }
    });
    if (!isValid) {
      return {
        isValid: false,
        errorMessage: "Please fill out the required fields."
      };
    }
  }

  // Applies the filters selected by the user to filter the monthly payments
  applyFilters() {
    this.filteredMonthlyPayments = this.monthlyPayments
      .filter((roomData) => {
        const roomDate = new Date(`${roomData.year}-${roomData.month}-01`);
        const isWithinDateRange =
          (this.startMonthFilter == null &&
            this.startYearFilter != null &&
            roomData.year >= this.startYearFilter &&
            ((this.endYearFilter !== null &&
              roomData.year <= this.endYearFilter) ||
              this.endYearFilter == null)) ||
          (roomDate >=
            new Date(`${this.startYearFilter}-${this.startMonthFilter}-01`) &&
            roomDate <=
              new Date(`${this.endYearFilter}-${this.endMonthFilter}-01`));
        return this.allNullForFilter() || isWithinDateRange;
      })
      .map((item) => {
        const filteredRooms = item.data.filter(
          (dataItem) =>
            dataItem.room == this.productSelectedFilter ||
            this.productSelectedFilter == null ||
            this.productSelectedFilter == "All"
        );
        if (filteredRooms.length > 0) {
          return {
            ...item,
            data: filteredRooms,
            total: filteredRooms.reduce((acc, curr) => acc + curr.finalPrice, 0)
          };
        }
        return null;
      })
      .filter((item) => item !== null);
    if (this.allNullForFilter() && this.productSelectedFilter == null) {
      this.generateComboboxOptions(this.monthlyPayments, false);
    } else {
      this.generateComboboxOptions(this.filteredMonthlyPayments, true);
    }

    const event = new CustomEvent("submitfilters", {
      detail: this.filters
    });
    this.dispatchEvent(event);
  }

  resetSelectedValues() {
    this.startYear = null;
    this.startMonth = null;
    this.endYear = null;
    this.endMonth = null;
    this.globalDiscount = 0;
    this.globalFinalPriceForProductSelected = null;
    this.yearToApplyDiscount = null;
    this.isLocationDisabled = false;
    this.isAreaDisabled = false;
  }

  // Resets selected filter values and clears current filters
  resetSelectedFilterValues() {
    this.startYearFilter = null;
    this.startMonthFilter = null;
    this.endYearFilter = null;
    this.endMonthFilter = null;
    this.productSelectedFilter = null;
    this.areaSelectedFilter = null;
    this.locationSelectedFilter = null;
    this.productFamilySelectedFilter = null;
    this.productTypeSelectedFilter = null;
    this.productSubTypeSelectedFilter = null;
    this.isLocationDisabled = false;
    this.isAreaDisabled = false;

    this.filters = {};
    this.applyFilters();
  }
  allNullForFilter() {
    return (
      this.startYearFilter == null &&
      this.startMonthFilter == null &&
      this.endYearFilter == null &&
      this.endMonthFilter == null
    );
  }
  displayToast(message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        message: message,
        variant: variant
      })
    );
  }
}