import getMonthlyPayments from "@salesforce/apex/OpportunityService.getMonthlyPayments";
import updateDiscount from "@salesforce/apex/OpportunityService.updateDiscount";
import { onError, subscribe, unsubscribe } from "lightning/empApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import { api, LightningElement, track, wire } from "lwc";

import allProducts from "@salesforce/label/c.rooms_allProducts";
import allTime from "@salesforce/label/c.rooms_allTime";
import amountInput from "@salesforce/label/c.rooms_amountInput";
import amountOpt_btnRadio from "@salesforce/label/c.rooms_amountOpt_btnRadio";
import applyDiscount_btn from "@salesforce/label/c.rooms_applyDiscount_btn";
import asc_btn from "@salesforce/label/c.rooms_asc_btn";
import calcPriceAdj from "@salesforce/label/c.rooms_calcPriceAdj";
import custom_btnRadio from "@salesforce/label/c.rooms_custom_btnRadio";
import desc_btn from "@salesforce/label/c.rooms_desc_btn";
import labelDiscount from "@salesforce/label/c.rooms_discount";
import discountMultiple from "@salesforce/label/c.rooms_discountMultiple";
import discountPercentage from "@salesforce/label/c.rooms_discountPercentage";
import priceAdjBlockTitle from "@salesforce/label/c.rooms_discounts_title";
import displayFilter from "@salesforce/label/c.rooms_displayFilter";
import filtersTitle_label from "@salesforce/label/c.rooms_filtersTitle_label";
import finalPrice from "@salesforce/label/c.rooms_finalPrice";
import finalPriceToApply from "@salesforce/label/c.rooms_finalPriceToApply";
import helpText from "@salesforce/label/c.rooms_HelpText";
import listPrice from "@salesforce/label/c.rooms_listPrice";
import monthlySaving_caption from "@salesforce/label/c.rooms_monthlySaving_caption";
import applyFilter_btn from "@salesforce/label/c.rooms_oppDiscount_applyFilters";
import checkbox from "@salesforce/label/c.rooms_oppDiscount_checkbox";
import endMonth_label from "@salesforce/label/c.rooms_oppDiscount_endMonth";
import endYear_label from "@salesforce/label/c.rooms_oppDiscount_endYear";
import startMonth_label from "@salesforce/label/c.rooms_oppDiscount_startMonth";
import startYear_label from "@salesforce/label/c.rooms_oppDiscount_startYear";
import priceAdj from "@salesforce/label/c.rooms_OppTable_PriceAdj";
import orderByDate from "@salesforce/label/c.rooms_orderByDate";
import percentageOpt_btnRadio from "@salesforce/label/c.rooms_percentageOpt_btnRadio";
import productsLabel from "@salesforce/label/c.rooms_productsLabel";
import roomTitle from "@salesforce/label/c.rooms_roomTtitle";
import simulateDiscount_btn from "@salesforce/label/c.rooms_simulateDiscount_btn";
import totalPrice from "@salesforce/label/c.rooms_totalPrice";
import year_btnRadio from "@salesforce/label/c.rooms_year_btnRadio";
import yearToApplyDiscount from "@salesforce/label/c.rooms_yearToApplyDiscount";

export default class MonthlyPaymentTable extends NavigationMixin(
  LightningElement
) {
  @track monthlyPayments = [];
  @track initialMonthlyPayments = [];
  @track filteredMonthlyPayments = [];
  @track grandTotal = 0;
  @api recordId;
  @api productsDate = [];
  @track selectedProducts = [];
  @track applyOnFinalPrice = false;

  startMonth;
  startYear;
  endMonth;
  endYear;
  productSelectedFilter;
  startMonthFilter;
  startYearFilter;
  endMonthFilter;
  globalFinalPriceForProductSelected;
  endYearFilter;
  monthlyPaymentsForReset;
  yearToApplyDiscount;
  AggregatedListPriceAdjustment;
  calculatedListPriceAdjustment;
  discountFormat = "Percentage";
  sortOrder = "ASC";
  discountApplyChoice = "Year";
  years = [];
  months = [];
  products = [];
  yearsDate = [];
  monthsDate = [];
  isYear = true;
  isSimulate = true;

  customLabels = {
    discountMultiple,
    priceAdjBlockTitle,
    yearToApplyDiscount,
    startMonth_label,
    startYear_label,
    endMonth_label,
    endYear_label,
    amountInput,
    finalPriceToApply,
    simulateDiscount_btn,
    applyDiscount_btn,
    filtersTitle_label,
    displayFilter,
    orderByDate,
    applyFilter_btn,
    totalPrice,
    finalPrice,
    discountPercentage,
    listPrice,
    roomTitle,
    monthlySaving_caption,
    asc_btn,
    desc_btn,
    year_btnRadio,
    custom_btnRadio,
    percentageOpt_btnRadio,
    amountOpt_btnRadio,
    allProducts,
    allTime,
    labelDiscount,
    priceAdj,
    helpText,
    productsLabel,
    calcPriceAdj,
    checkbox
  };

  //platform event handling
  subscription = {};
  channelName = "/event/MonthlyPaymentAdded__e";

  globalDiscount = "";
  optionsDiscount = [
    { label: this.customLabels.amountOpt_btnRadio, value: "Amount" },
    { label: this.customLabels.percentageOpt_btnRadio, value: "Percentage" }
  ];
  optionsDateDiscount = [
    { label: this.customLabels.year_btnRadio, value: "Year" },
    { label: this.customLabels.custom_btnRadio, value: "Custom" }
  ];
  optionsSortOrder = [
    { label: this.customLabels.asc_btn, value: "ASC" },
    { label: this.customLabels.desc_btn, value: "DESC" }
  ];
  inlineCss = "";
  @api objectApiName;

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
  connectedCallback() {
    this.handleSubscribe();
    this.getData();
  }
  mapLocationNameToId = new Map();

  // Retrieves monthly payment data and initializes filter options
  getData() {
    let data;
    getMonthlyPayments({
      oppId: this.objectApiName == "Opportunity" ? this.recordId : null,
      contractId: this.objectApiName == "Contract" ? this.recordId : null
    }).then((result) => {
      if (result) {
        data = result;

        this.monthlyPayments = this.transformData(data);
        console.log(
          "get monthly payment = ",
          JSON.stringify(this.monthlyPayments, null, 4)
        );

        this.initialMonthlyPayments = JSON.parse(
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

  handleApplyOnFinalPriceChange(event) {
    this.applyOnFinalPrice = event.target.checked;
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
          (parseFloat(event.target.value, 10) || 0) + increment;
        roomData[0].discount =
          100 - (100 * roomData[0].finalPrice) / roomData[0].listPrice;
        roomData[0].discount =
          roomData[0].discount % 1 != 0
            ? -(Math.round(roomData[0].discount * 100) / 100)
            : -roomData[0].discount;
        roomData[0].isDiscountArrow = true;
      } else {
        roomData[0].discount =
          (parseFloat(event.target.value) || 0) + increment;
        roomData[0].finalPrice =
          roomData[0].listPrice +
          (roomData[0].listPrice * roomData[0].discount) / 100;
        roomData[0].isDiscountArrow = false;
      }
    }
  }

  handleDiscountMultipleValue(e) {
    const name = e.target.name;
    const value = e.target.value;

    if (value === "All") {
      this[name] = "All";
    } else {
      this[name] = this.cleanAndConvertToNumber(value);
    }
  }

  // Generates options for combobox filters based on unique values in data
  generateComboboxOptions(data, isAfterFilter) {
    const roomMap = new Map(); // Clé = roomId, pour éviter les doublons par mois
    const months = new Set();
    const years = new Set();

    // Étape 1 : collecter les rooms uniques
    data.forEach((entry) => {
      months.add(entry.month);
      years.add(entry.year);

      entry.data.forEach((item) => {
        const key = item.room;
        if (!roomMap.has(key)) {
          roomMap.set(key, {
            displayName: item.displayName,
            roomId: item.room
          });
        }
      });
    });

    // Étape 2 : identifier les noms en doublon
    const displayNameCount = {};
    const totalDisplayNameCount = {};

    const uniqueProducts = Array.from(roomMap.values());

    uniqueProducts.forEach((prod) => {
      const name = prod.displayName;
      totalDisplayNameCount[name] = (totalDisplayNameCount[name] || 0) + 1;
    });

    // Étape 3 : format final avec #1, #2 si doublons
    this.productsDate = uniqueProducts.map((prod) => {
      const name = prod.displayName;
      let label = name;
      if (totalDisplayNameCount[name] > 1) {
        displayNameCount[name] = (displayNameCount[name] || 0) + 1;
        label = `${name} #${displayNameCount[name]}`;
      }
      return {
        label: label,
        value: prod.roomId
      };
    });

    // Ajout de "All Products"
    this.productsDate.push({
      label: this.customLabels.allProducts,
      value: "All"
    });

    // Mois + années
    this.monthsDate = Array.from(months)
      .map((month) => ({ label: month, value: month }))
      .sort((a, b) => a.value - b.value);

    this.yearsDate = Array.from(years).map((year) => ({
      label: year,
      value: year
    }));

    if (!isAfterFilter) {
      this.yearsDate.push({
        label: this.customLabels.allTime,
        value: "All"
      });
    }

    console.log("✅ productsDate:", JSON.stringify(this.productsDate, null, 2));
  }

  get rooms() {
    const roomSet = new Set();
    this.filteredMonthlyPayments.forEach((monthData) => {
      monthData.data.forEach((data) => {
        console.log("data.room :", data.room);
        roomSet.add(data.room);
      });
    });
    return Array.from(roomSet);
  }
  sumTotalPrice = 0;

  get dataByRoom() {
    this.sumTotalPrice = 0;
    this.totalCalculatedPriceAdj = 0;

    const uniqueDisplayByRoom = new Map();

    // Étape 1 — collecter un mapping roomId → displayName
    this.filteredMonthlyPayments.forEach((monthData) => {
      monthData.data.forEach((item) => {
        if (!uniqueDisplayByRoom.has(item.room)) {
          uniqueDisplayByRoom.set(item.room, item.displayName);
        }
      });
    });

    // Étape 2 — comptage global par displayName
    const displayNameCount = {};
    const totalDisplayNameCount = {};

    Array.from(uniqueDisplayByRoom.values()).forEach((name) => {
      totalDisplayNameCount[name] = (totalDisplayNameCount[name] || 0) + 1;
    });

    const displayNameIndexMap = {};

    const data = this.rooms.map((room) => {
      const firstMonthRoomData = this.filteredMonthlyPayments
        .find(
          (month) => month.data && month.data.some((data) => data.room === room)
        )
        ?.data.find((data) => data.room === room);

      const rawDisplayName = firstMonthRoomData?.displayName || "";
      let displayName = rawDisplayName;

      // Ajout du suffixe uniquement si doublon réel
      if (totalDisplayNameCount[rawDisplayName] > 1) {
        displayNameIndexMap[rawDisplayName] =
          (displayNameIndexMap[rawDisplayName] || 0) + 1;
        displayName = `${rawDisplayName} #${displayNameIndexMap[rawDisplayName]}`;
      }

      return {
        room: room,
        deskcount: firstMonthRoomData?.deskcount || 0,
        displayName: displayName,
        calculateListPriceAdj: firstMonthRoomData?.calculateListPriceAdj || 0,
        values: this.filteredMonthlyPayments.map((monthData) => {
          const roomData = monthData.data.find((data) => data.room === room);
          return {
            month: monthData.month,
            year: monthData.year,
            listPrice: roomData
              ? Math.round(roomData.listPrice * 100) / 100
              : "",
            discount: roomData ? parseFloat(roomData.discount).toFixed(2) : "",
            monthUnit: roomData ? roomData.monthUnit : "",
            finalPrice: roomData
              ? Math.round(roomData.finalPrice * 100) / 100
              : "",
            isDiscountArrow: roomData ? roomData.discount < 0 : null,
            calculatedPriceAdj:
              roomData?.calculatedPriceAdj != null
                ? roomData.calculatedPriceAdj
                : 0
          };
        })
      };
    });

    // Total par ligne
    data.forEach((row) => {
      const total = row.values.reduce((sum, val) => {
        const price = parseFloat(val.finalPrice);
        return sum + (isNaN(price) ? 0 : price);
      }, 0);

      const priceAdj = row.values[0].calculatedPriceAdj;
      row.Total =
        total % 1 === 0 ? parseFloat(total) : parseFloat(total.toFixed(2));
      row.calculatedPriceAdj =
        priceAdj % 1 === 0
          ? parseFloat(priceAdj)
          : parseFloat(priceAdj.toFixed(2));

      this.sumTotalPrice += row.Total;
      this.totalCalculatedPriceAdj += row.calculatedPriceAdj;
    });

    this.sumTotalPrice = this.sumTotalPrice.toFixed(2);
    this.totalCalculatedPriceAdj = this.totalCalculatedPriceAdj.toFixed(2);

    return data;
  }

  get totalsByMonth() {
    let dataTotal = this.filteredMonthlyPayments.map((monthData) => {
      let totalListPrice = monthData.data.reduce((sum, data) => {
        let listPrice = parseFloat(data.listPrice) || 0;
        return sum + listPrice;
      }, 0);

      if (typeof totalListPrice === "number") {
        totalListPrice =
          totalListPrice % 1 !== 0
            ? parseFloat(totalListPrice.toFixed(2))
            : Math.floor(totalListPrice);
      }

      const weightedDiscountSum = monthData.data.reduce((sum, item) => {
        let listPrice = parseFloat(item.listPrice) || 0;
        let discount = parseFloat(item.discount) || 0;
        return sum + listPrice * discount;
      }, 0);

      let totalFinalPrice = monthData.data.reduce((sum, data) => {
        let finalPrice = parseFloat(data.finalPrice) || 0;
        return sum + finalPrice;
      }, 0);

      if (typeof totalFinalPrice === "number") {
        totalFinalPrice =
          totalFinalPrice % 1 !== 0
            ? parseFloat(totalFinalPrice.toFixed(2))
            : Math.floor(totalFinalPrice);
      }

      let totalDiscount =
        totalListPrice !== 0 ? weightedDiscountSum / totalListPrice : 0;
      if (typeof totalDiscount === "number") {
        totalDiscount =
          totalDiscount % 1 !== 0
            ? parseFloat(totalDiscount.toFixed(2))
            : Math.floor(totalDiscount);
      }

      return {
        month: monthData.month,
        year: monthData.year,
        totalListPrice,
        totalDiscount,
        totalFinalPrice
      };
    });

    return dataTotal;
  }

  get isProductSelected() {
    return this.selectedProducts !== null && this.selectedProducts.length > 0;
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
        oppproductid: payment.OpportunityLineItem__c || payment.OrderItem__c,
        room: payment.OpportunityLineItem__c || payment.OrderItem__c,
        displayName: payment.Products_Name__c,
        calculateListPriceAdj:
          this.objectApiName === "Opportunity"
            ? payment.OpportunityLineItem__r
                ?.Calculated_List_Price_Adjustment__c || 0
            : payment.OrderItem__r?.Calculated_List_Price_Adjustment__c || 0,
        deskcount:
          this.objectApiName == "Opportunity"
            ? payment.OpportunityLineItem__r.Desk_Count__c
            : payment.OrderItem__r.Number_of_desks__c,
        listPrice: payment.Price__c,
        discount: payment.Discount__c || 0,
        monthUnit: payment.Monthly_Units__c || 1,
        finalPrice:
          payment.Price__c +
          (payment.Price__c * (payment.Discount__c || 0)) / 100
      });
      groupedData[key].total +=
        parseFloat(payment.Price__c) +
        (parseFloat(payment.Price__c) *
          (parseFloat(payment.Discount__c) || 0)) /
          100;
    });

    return Object.values(groupedData);
  }

  handleDiscountChange(event) {
    let priceChange = event.target.value;
    let isDiscount = priceChange.includes("-"); // Check if there's a minus sign

    const { month, year, room } = event.target.dataset;
    const monthYearData = this.monthlyPayments.filter(
      (item) => item.month == month && item.year == year
    );
    if (monthYearData.length === 0) {
      return null;
    }
    const roomData = monthYearData[0].data.filter((item) => item.room === room);
    roomData[0].discount = parseFloat(priceChange.replace(/[^0-9.-]/g, ""));
    roomData[0].discount =
      roomData[0].discount % 1 != 0
        ? parseFloat((roomData[0].discount * 100) / 100)
        : roomData[0].discount;

    roomData[0].finalPrice = isDiscount
      ? parseFloat(
          roomData[0].listPrice - (roomData[0].listPrice * -priceChange) / 100
        )
      : parseFloat(
          roomData[0].listPrice + (roomData[0].listPrice * priceChange) / 100
        );
    roomData[0].isDiscountArrow = isDiscount;

    this.applyFilters();
    this.isSimulate = false;
    this.saveRecords();
  }

  handleFinalPriceChange(event) {
    const input = event.target.value.replace(/[^0-9.]/g, "");
    // Replace any non-numeric characters with an empty string
    const { month, year, room } = event.target.dataset;
    const monthYearData = this.monthlyPayments.filter(
      (item) => item.month == month && item.year == year && item.data.length > 0
    );
    if (monthYearData.length === 0) {
      return null;
    }
    const roomData = monthYearData[0].data.filter((item) => item.room === room);
    roomData[0].finalPrice =
      parseFloat(input) % 1 !== 0 ? parseFloat(input) : parseInt(input, 10);
    roomData[0].discount =
      100 - (100 * roomData[0].finalPrice) / roomData[0].listPrice;
    roomData[0].discount =
      roomData[0].discount % 1 != 0
        ? parseFloat((roomData[0].discount * 100) / 100)
        : roomData[0].discount;
    roomData[0].discount = -roomData[0].discount;

    this.applyFilters();
    this.isSimulate = false;
    this.saveRecords();
  }
  handleFormatDiscount(event) {
    if (
      event.target.name == "discountApplyChoice" &&
      this[event.target.name] != event.target.value
    ) {
      this.resetPriceOptimizerBlock();
    }

    this[event.target.name] = event.target.value;
    if (event.target.name === "discountApplyChoice") {
      this.isYear = this.discountApplyChoice === "Year";
    } else if (event.target.name === "sortOrder") {
      this.sortData(this.filteredMonthlyPayments, this.sortOrder);
    }
  }

  sortData(data, sortOrder) {
    data.sort((a, b) => {
      if (a.year === b.year) {
        return sortOrder === "ASC" ? a.month - b.month : b.month - a.month;
      } else {
        return sortOrder === "ASC" ? a.year - b.year : b.year - a.year;
      }
    });
  }
  calculateDiscountPercentage(initialPrice, discountAmount) {
    const discountPercentage = (discountAmount * 100) / initialPrice;
    return discountPercentage;
  }

  resetTable() {
    this.filteredMonthlyPayments = this.initialMonthlyPayments;
    this.monthlyPayments = this.initialMonthlyPayments;
    this.generateComboboxOptions(this.initialMonthlyPayments, false);
  }

  resetFilters() {
    this.resetSelectedFilterValues();
    this.resetTable();
    this.generateComboboxOptions(this.monthlyPayments, false);
  }

  cleanAndConvertToNumber(value) {
    if (value != null) {
      const valueStr = String(value).replace(/\s/g, "").replace(",", ".");
      const sanitized = valueStr.replace(/[^0-9.]/g, "");
      const dotCount = (sanitized.match(/\./g) || []).length;
      if (dotCount > 1) {
        return 0;
      }
      const num = parseFloat(sanitized);
      return isNaN(num) ? 0 : num;
    }
    return null;
  }

  handleProductsChange(event) {
    this.selectedProducts = event.detail.value;
  }

  // Handles discount application to monthly payments based on selected discount settings
  simulateDiscount() {
    if (!this.isSimulate) return;
    let startDate;
    let endDate;
    if (!this.isYear) {
      startDate = new Date(`${this.startYear}-${this.startMonth}-01`);
      endDate = new Date(`${this.endYear}-${this.endMonth}-01`);
    }
    this.validate();

    this.monthlyPayments.forEach((roomData) => {
      const roomDate = new Date(`${roomData.year}-${roomData.month}-01`);
      if (
        (this.isYear &&
          ((roomData.year == this.yearToApplyDiscount &&
            this.monthsDate.some((obj) => obj.value === roomData.month)) ||
            this.yearToApplyDiscount == "All")) ||
        (!this.isYear && roomDate >= startDate && roomDate <= endDate)
      ) {
        roomData.data.forEach((paymentData) => {
          console.log("@@@@@@", paymentData.room);

          if (this.selectedProducts) {
            if (
              this.selectedProducts.includes(paymentData.room) ||
              this.selectedProducts.includes("All")
            ) {
              let globalPrice = this.cleanAndConvertToNumber(
                this.globalFinalPriceForProductSelected
              );
              let { listPrice, monthUnit } = paymentData;

              if (globalPrice && this.isProductSelected) {
                paymentData.finalPrice = globalPrice * monthUnit;
                paymentData.discount =
                  paymentData.finalPrice < listPrice
                    ? -(100 - (100 * paymentData.finalPrice) / listPrice)
                    : (100 * paymentData.finalPrice) / listPrice - 100;
              } else {
                paymentData = this.simulatePaymentDiscount(paymentData);
              }

              paymentData.discount = parseFloat(paymentData.discount);
            }
          }
        });
      }
    });

    this.filteredMonthlyPayments = this.monthlyPayments;
    this.applyFilters();
  }

  simulatePaymentDiscount(paymentData) {
    let { listPrice, discount, monthUnit } = paymentData;

    let initialFinalPrice = listPrice * (1 + parseFloat(discount) / 100);
    let globalDiscountValue = parseFloat(this.globalDiscount);

    if (this.applyOnFinalPrice) {
      paymentData.finalPrice =
        this.discountFormat === "Percentage"
          ? initialFinalPrice * (1 + globalDiscountValue / 100)
          : initialFinalPrice + globalDiscountValue;

      paymentData.discount = -(
        ((listPrice - paymentData.finalPrice) / listPrice) *
        100
      );
    } else {
      paymentData.discount =
        this.discountFormat === "Percentage"
          ? globalDiscountValue
          : this.calculateDiscountPercentage(
              listPrice,
              globalDiscountValue * monthUnit
            );

      paymentData.finalPrice =
        this.discountFormat === "Percentage"
          ? listPrice * (1 + paymentData.discount / 100)
          : listPrice + globalDiscountValue;
    }
    return paymentData;
  }

  get isApplyDiscountDisabled() {
    const hasDiscountOrFinalPrice =
      (this.globalDiscount !== "" && this.globalDiscount != null) ||
      (this.globalFinalPriceForProductSelected !== "" &&
        this.globalFinalPriceForProductSelected != null);
    const hasSelectedProducts =
      this.selectedProducts && this.selectedProducts.length > 0;
    const hasValidDateRange =
      this.startMonth && this.startYear && this.endMonth && this.endYear;
    const hasYearOrAllTime =
      this.yearToApplyDiscount != null && this.yearToApplyDiscount !== "";
    return !(
      hasDiscountOrFinalPrice &&
      hasSelectedProducts &&
      (hasValidDateRange || hasYearOrAllTime)
    );
  }

  get isGlobalFinalPriceDisplayed() {
    return (
      this.selectedProducts.length > 0 &&
      this.yearToApplyDiscount != null &&
      this.yearToApplyDiscount !== ""
    );
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

  get discountEnter() {
    return !!this.globalDiscount;
  }

  // Applies selected filters to the list of monthly payments
  applyFilters() {
    this.filteredMonthlyPayments = this.monthlyPayments
      .filter((roomData) => {
        const roomDate = new Date(
          `${roomData.year}-${roomData.month || "01"}-01`
        );

        const isEndYearAll = this.endYearFilter === "All";
        const isStartYearAll = this.startYearFilter === "All";

        const startFilterDate = isStartYearAll
          ? new Date(`${roomData.year}-${roomData.month || "01"}-01`)
          : new Date(
              `${this.startYearFilter}-${this.startMonthFilter || "01"}-01`
            );

        const endFilterDate = isEndYearAll
          ? new Date(`${roomData.year + 1}-01-01`)
          : new Date(`${this.endYearFilter}-${this.endMonthFilter || "12"}-01`);

        const isWithinDateRange =
          (isStartYearAll && roomDate <= endFilterDate) ||
          (isEndYearAll && roomDate >= startFilterDate) ||
          (roomDate >= startFilterDate && roomDate <= endFilterDate);

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
  }

  resetSelectedValues() {
    this.startYear = null;
    this.startMonth = null;
    this.endYear = null;
    this.endMonth = null;
    this.globalDiscount = 0;
    this.globalFinalPriceForProductSelected = null;
    this.yearToApplyDiscount = null;
    this.selectedProducts = [];
  }
  resetSelectedFilterValues() {
    this.startYearFilter = null;
    this.startMonthFilter = null;
    this.endYearFilter = null;
    this.endMonthFilter = null;
    this.productSelectedFilter = null;
    this.applyFilters();
  }

  resetPriceOptimizerBlock() {
    this.resetTable();
    this.resetSelectedValues();
    this.discountFormat = "Percentage";
  }

  allNullForFilter() {
    return (
      this.startYearFilter == null &&
      this.startMonthFilter == null &&
      this.endYearFilter == null &&
      this.endMonthFilter == null
    );
  }

  // Saves updated discount data to server after simulation
  saveRecords() {
    this.simulateDiscount();
    const result = this.filteredMonthlyPayments.flatMap((monthlyPayment) =>
      monthlyPayment.data.map((record) => ({
        Id: record.id,
        Discount__c: parseFloat(record.discount)
      }))
    );
    updateDiscount({ payments: result })
      .then((response) => {
        response
          ? this.displayToast("Records updated successfully", "success")
          : this.displayToast("Failed to update discounts", "error");
        this.initialMonthlyPayments = this.filteredMonthlyPayments;
        this.isSimulate = true;
        this.getData();
      })
      .catch((error) => {
        this.displayToast(error.body.message, "error");
        console.log("Error on saving record: " + JSON.stringify(error));
      });
  }

  redirectToRoom(ev) {
    const roomName = ev.target.dataset.room;
    const recordId = this.mapLocationNameToId.get(roomName);
    if (recordId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: recordId,
          actionName: "view"
        }
      });
    } else {
      console.warn(`No recordId found for room: ${roomName}`);
    }
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