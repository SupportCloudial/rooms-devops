import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";

import getOppProducts from "@salesforce/apex/OpportunityProductController.getOppProducts";
//import totalTableNotAvailable from '@salesforce/apex/OpportunityProductController.totalTableNotAvailable';
import saveLineItems from "@salesforce/apex/OpportunityProductController.saveLineItems";
import deleteLineItems from "@salesforce/apex/OpportunityProductController.deleteLineItems";
import showAvailabilityModal from "c/showAvailabilityModal";
import None from "@salesforce/label/c.PackageBuilder_None";
import Delete from "@salesforce/label/c.PackageBuilder_Delete";
import PackageBuilderTblName from "@salesforce/label/c.PackageBuilderTbl_Name";
import DeskUnitPrice from "@salesforce/label/c.PackageBuilderTbl_DeskUnitPrice";
import DesksUnits from "@salesforce/label/c.PackageBuilderTbl_DesksUnits";
import EntryPaymentDate from "@salesforce/label/c.PackageBuilderTbl_EntryPaymentDate";
import EndDate from "@salesforce/label/c.PackageBuilderTbl_EndDate";
import EntryDate from "@salesforce/label/c.PackageBuilderTbl_EntryDate";
import Quantity from "@salesforce/label/c.PackageBuilderTbl_Quantity";
import ListPrice from "@salesforce/label/c.AddProductsTbl_ListPrice";
import TotalPrice from "@salesforce/label/c.PackageBuilderTbl_TotalPrice";
import ExternalRoom from "@salesforce/label/c.PackageBuilderTbl_ExternalRoom";
import Temporary from "@salesforce/label/c.PackageBuilderTbl_Temporary";
import Notes from "@salesforce/label/c.PackageBuilderTbl_Notes";
import QuickUpdate from "@salesforce/label/c.PackageBuilder_QuickUpdate";
import AccessType from "@salesforce/label/c.PackageBuilder_AccessType";
import AccessTypePHLabel from "@salesforce/label/c.PackageBuilder_AccessTypePH";
import Entry from "@salesforce/label/c.PackageBuilder_Entry";
import DeskPrice from "@salesforce/label/c.PackageBuilder_DeskPrice";
import Exit from "@salesforce/label/c.PackageBuilder_Exit";
import MassUpdateBtn from "@salesforce/label/c.PackageBuilder_MassUpdateBtn";
import MassDeleteBtn from "@salesforce/label/c.PackageBuilder_MassDeleteBtn";
import SaveError from "@salesforce/label/c.PackageBuilder_SaveError";
import Error from "@salesforce/label/c.AddProducts_Error";
import AddProductSuccess from "@salesforce/label/c.PackageBuilder_AddProductSuccess";
import SaveTableError from "@salesforce/label/c.PackageBuilder_SaveTableError";
import DeleteProductSuccess from "@salesforce/label/c.PackageBuilder_DeleteProductSuccess";
import Cancel from "@salesforce/label/c.PackageBuilder_Cancel";
import Availability from "@salesforce/label/c.PackageBuilder_Availability";
import AvailableStatus from "@salesforce/label/c.PackageBuilder_AvailableStatus";
import PartlyAvailableStatus from "@salesforce/label/c.PackageBuilder_PartlyAvailableStatus";
import NotAvailableStatus from "@salesforce/label/c.PackageBuilder_NotAvailableStatus";
import PrdAvailability from "@salesforce/label/c.PackageBuilder_PrdAvailability";
import AverageDeskPrice from "@salesforce/label/c.PackageBuilder_AverageDeskPrice";
import Desks from "@salesforce/label/c.PackageBuilder_Desks";
import ListPriceSum from "@salesforce/label/c.PackageBuilder_ListPriceSum";
import MonthlyPrice from "@salesforce/label/c.PackageBuilder_Monthly_Price";
import QuantitySum from "@salesforce/label/c.PackageBuilder_Quantity_Sum";
import TotalPriceOther from "@salesforce/label/c.PackageBuilder_TotalPriceOther";
import ListPriceAdjustment from "@salesforce/label/c.PackageBuilder_ListPriceAdjustment";
import TemporaryProductCheck from "@salesforce/label/c.PackabeBuilder_TemporaryProductCheck";

export default class PackageBuilderTable extends LightningElement {
  labels = {
    None,
    Delete,
    AccessType,
    AccessTypePHLabel,
    Entry,
    DeskPrice,
    Exit,
    MassUpdateBtn,
    MassDeleteBtn,
    PackageBuilderTblName,
    DeskUnitPrice,
    DesksUnits,
    EntryPaymentDate,
    EndDate,
    EntryDate,
    Quantity,
    ListPrice,
    TotalPrice,
    ExternalRoom,
    Temporary,
    Notes,
    QuickUpdate,
    SaveError,
    Error,
    AddProductSuccess,
    SaveTableError,
    DeleteProductSuccess,
    Cancel,
    Availability,
    AvailableStatus,
    PartlyAvailableStatus,
    NotAvailableStatus,
    PrdAvailability,
    AverageDeskPrice,
    Desks,
    ListPriceSum,
    MonthlyPrice,
    QuantitySum,
    TotalPriceOther,
    ListPriceAdjustment,
    TemporaryProductCheck
  };

  @api recordId; //oppId
  @track draftValues = [];
  @track errors = {};
  @track productsData = [];

  oppRecordTypeName;
  oppAverageDeskPrice;
  oppDesks;
  oppListPriceSum;
  oppMonthlyPrice;
  oppQuantitySum;
  oppTotalPriceNonStandard;
  oppListPriceAdjustment;
  oppAggregateCalculatedTotalPrice;
  oppTemporaryProductCheck;
  oppRecordTypeId = "";
  columns;
  editable = true;
  selectedRows = [];
  wiredLineItemsResult; // Store wire result for refresh

  //mass update fields
  accessTypeOptions;
  selectedAccessType = "";
  selectedDesksPrice;
  selectedEntryDate = "";
  selectedEndDate = "";
  selectedTotalPrice = "";

  @wire(getOppProducts, { oppId: "$recordId" })
  wiredLineItems(result) {
    this.wiredLineItemsResult = result; // Store the result to use in refreshApex
    const { data, error } = result;

    if (data) {
      //console.log('data' + data);

      this.productsData = data.map((prod) => {
        return {
          ...prod,
          AvailabilityIcon: this.getProductAvailabilityIcon(prod.Availability)
        };
      });

      if (data.length > 0) {
        this.oppRecordTypeName = data[0].oppRecordTypeName;
        this.oppRecordTypeId = data[0].oppRecordTypeId;
        this.oppAverageDeskPrice = data[0].oppAverageDeskPrice;
        this.oppDesks = data[0].oppDesks;
        this.oppListPriceSum = data[0].oppListPriceSum;
        this.oppMonthlyPrice = data[0].oppMonthlyPrice;
        this.oppQuantitySum = data[0].oppQuantitySum;
        // ajouter ici
        this.oppAggregateCalculatedTotalPrice =
          data[0].oppAggregateCalculatedTotalPrice;
        this.oppTotalPriceNonStandard = data[0].oppTotalPriceNonStandard;
        this.oppListPriceAdjustment = data[0].oppListPriceAdjustment;
        this.oppTemporaryProductCheck = data[0].oppTemporaryProductCheck;
      }

      if (this.oppRecordTypeName == "Standard Opportunity") {
        this.setStandardOppColumns();
      } else {
        this.setOnDemandOppColumns();
      }
    } else if (error) {
      console.error("Error fetching line items:", error);
    }
  }

  getProductAvailabilityIcon(availability) {
    let icon;

    switch (availability) {
      case this.labels.AvailableStatus:
        icon = "🟢"; //'utility:success';
        break;
      case this.labels.PartlyAvailableStatus:
        icon = "⚠️"; //'utility:warning';
        break;
      case this.labels.NotAvailableStatus:
        icon = "🚫"; //'utility:error';
        break;
      default:
    }
    //icon =  '🔴'; //'🟡' //'🟢' //'🆓' // '🚫' //'⚠️' //'✅'
    return icon;
  }

  /*getProductAvailabilityCls(availability){
        let cls;

        switch (availability) {
            case 'Available':
                cls = 'slds-icon-text-success';
                break;
            case 'Partly Available':
                cls = 'slds-icon-text-warning';
                break;
            case 'Not Available':
                cls = 'slds-icon-text-error';
                break;
            default:
        }

        return cls;
    }*/

  @api
  refreshProductsTable() {
    refreshApex(this.wiredLineItemsResult);
  }

  // Get picklist values by record type
  @wire(getPicklistValuesByRecordType, {
    objectApiName: OPPORTUNITY_OBJECT,
    recordTypeId: "$oppRecordTypeId"
  })
  picklistValues({ error, data }) {
    if (data) {
      this.accessTypeOptions = this.parsePicklist(
        data.picklistFieldValues.Product_Access_Type__c
      );
      this.accessTypeOptions = [
        { label: this.labels.None, value: "" },
        ...this.accessTypeOptions
      ];
    } else if (error) {
      console.error("Error fetching picklist values", error);
    }
  }

  parsePicklist(picklistField) {
    return picklistField.values.map((item) => ({
      label: item.label,
      value: item.value
    }));
  }

  setStandardOppColumns() {
    this.columns = [
      {
        label: this.labels.PackageBuilderTblName,
        fieldName: "Name",
        initialWidth: 100
      },
      {
        label: this.labels.Availability,
        type: "button",
        cellAttributes: { alignment: "center" },
        typeAttributes: {
          label: { fieldName: "AvailabilityIcon" },
          name: "availability",
          variant: "base",
          title: { fieldName: "Availability" }
        },
        initialWidth: 50
      },
      //{ label: this.labels.Availability, type: 'button-icon', typeAttributes: {iconName: { fieldName: 'AvailabilityIcon' }, name: 'availability', iconClass: { fieldName: 'AvailabilityCls' }}},
      /*{ label: this.labels.Availability,typeAttributes:
                { 
                    iconClass: 'slds-icon-text-error'
                },cellAttributes: { iconName: { fieldName: 'AvailabilityIcon' }, iconClass: { fieldName: 'AvailabilityCls' }, class: { fieldName: 'AvailabilityCls' }}},*/
      {
        label: this.labels.DeskUnitPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "UnitPrice",
        editable: this.editable,
        initialWidth: 110
      },
      //{ label: this.labels.DesksUnits, type: 'number', cellAttributes: { alignment: 'left' }, fieldName: 'DeskCount', initialWidth: 115},
      {
        label: this.labels.AccessType,
        fieldName: "AccessType",
        initialWidth: 120
      },
      {
        label: this.labels.EntryPaymentDate,
        type: "date-local",
        typeAttributes: {
          dateStyle: "short",
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          timeZone: "UTC"
        },
        fieldName: "EntryDate",
        editable: this.editable,
        initialWidth: 110
      },
      {
        label: this.labels.EndDate,
        type: "date-local",
        typeAttributes: {
          dateStyle: "short",
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          timeZone: "UTC"
        },
        fieldName: "EndDate",
        editable: this.editable,
        initialWidth: 110
      },
      {
        label: this.labels.Quantity,
        type: "number",
        cellAttributes: { alignment: "left" },
        fieldName: "Quantity",
        editable: this.editable,
        initialWidth: 95
      },
      {
        label: this.labels.ListPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "ListPrice",
        initialWidth: 95
      },
      {
        label: this.labels.TotalPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "TotalPrice",
        initialWidth: 110,
        editable: this.editable
      },
      {
        label: this.labels.ExternalRoom,
        fieldName: "ExternalRoom",
        type: "boolean",
        initialWidth: 70
      },
      {
        label: this.labels.Temporary,
        fieldName: "Temporary",
        type: "boolean",
        editable: this.editable,
        initialWidth: 90
      },
      {
        label: this.labels.Notes,
        fieldName: "Description",
        editable: this.editable,
        initialWidth: 120
      },
      {
        type: "button-icon",
        typeAttributes: { iconName: "utility:delete", name: "delete-btn" },
        cellAttributes: { class: "sticky-action" }
      }
    ];
  }

  setOnDemandOppColumns() {
    this.columns = [
      {
        label: this.labels.PackageBuilderTblName,
        fieldName: "Name",
        initialWidth: 100
      },
      {
        label: this.labels.DeskUnitPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "UnitPrice",
        editable: this.editable,
        initialWidth: 110
      },
      //{ label: this.labels.DesksUnits, type: 'number', cellAttributes: { alignment: 'left' }, fieldName: 'DeskCount', initialWidth: 115},
      {
        label: this.labels.AccessType,
        fieldName: "AccessType",
        initialWidth: 120
      }, //https://developer.salesforce.com/docs/platform/lwc/guide/data-table-custom-types
      {
        label: this.labels.EntryDate,
        type: "date-local",
        typeAttributes: {
          dateStyle: "short",
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          timeZone: "UTC"
        },
        fieldName: "EntryDate",
        editable: this.editable,
        initialWidth: 110
      },
      {
        label: this.labels.Quantity,
        type: "number",
        cellAttributes: { alignment: "left" },
        fieldName: "Quantity",
        editable: this.editable,
        initialWidth: 95
      },
      {
        label: this.labels.ListPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "ListPrice",
        initialWidth: 95
      },
      {
        label: this.labels.TotalPrice,
        type: "currency",
        cellAttributes: { alignment: "left" },
        typeAttributes: { maximumFractionDigits: 2 },
        fieldName: "TotalPrice",
        initialWidth: 110,
        editable: this.editable
      },
      {
        label: this.labels.Notes,
        fieldName: "Description",
        editable: this.editable,
        initialWidth: 120
      },
      {
        type: "button-icon",
        typeAttributes: { iconName: "utility:delete", name: "delete-btn" }
      }
    ];
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case ("delete", "delete-btn"):
        this.deleteRow(row);
        break;
      case "availability":
        this.showAvailability(row);
        break;
      default:
    }
  }

  handleRowSelection(event) {
    this.selectedRows = event.detail.selectedRows;
  }

  showAvailability(row) {
    const { LineItemId } = row;

    //event.stopPropagation();

    showAvailabilityModal
      .open({
        btnOptions: [
          { val: "Cancel", label: this.labels.Cancel, variant: "natural" }
        ],
        content: "",
        header: this.labels.PrdAvailability,
        size: "medium",
        recordId: this.recordId
      })
      .then((result) => {
        if (result == "Close") {
        }
      });
  }

  deleteRow(row) {
    const { LineItemId } = row;
    let lineItems = [];
    lineItems.push(LineItemId);

    this.deleteProducts(lineItems);
  }

  deleteProducts(lineItemsToDelete) {
    //delete from db
    deleteLineItems({ itemIds: lineItemsToDelete })
      .then((result) => {
        if (result == "Success") {
          this.productsData = this.productsData.filter(
            (item) => !lineItemsToDelete.includes(item.LineItemId)
          );
          this.showToast(
            "Success",
            this.labels.DeleteProductSuccess,
            "success"
          );
        } else {
          this.showToast("Error", result, "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", this.labels.Error, "error");
        console.error("Error updating OpportunityLineItems:", error);
      });
  }

  handleSave(event) {
    let saveDraftValues = event.detail.draftValues;
    console.log(saveDraftValues);
    let lineItemIds = [];

    let lineData = saveDraftValues.map((item) => {
      lineItemIds.push(item.LineItemId); // Collecting LineItemId values
      return {
        Id: item.LineItemId,
        UnitPrice: item.UnitPrice,
        Access_Type__c: item.AccessType,
        Entry_Date__c: item.EntryDate,
        End_date__c: item.EndDate,
        Quantity: item.Quantity,
        TotalPrice: item.TotalPrice,
        Temporary__c: item.Temporary,
        Description: item.Description
      };
    });

    this.saveProducts(lineItemIds, lineData);
  }

  handleMassUpdate(event) {
    const lineItemIdsToUpdate = this.selectedRows.map((row) => row.LineItemId);

    // Create array of objects
    const lineItemsToUpdate = lineItemIdsToUpdate.map((id) => {
      let lineItem = { Id: id }; // Start with Id

      if (
        this.selectedAccessType &&
        this.selectedAccessType != this.labels.None
      )
        lineItem.Access_Type__c = this.selectedAccessType;
      if (this.selectedDesksPrice) lineItem.UnitPrice = this.selectedDesksPrice;
      if (this.selectedEntryDate)
        lineItem.Entry_Date__c = this.selectedEntryDate;
      if (this.selectedEndDate) lineItem.End_date__c = this.selectedEndDate;
      if (this.selectedTotalPrice)
        lineItem.TotalPrice_c = this.selectedTotalPrice;

      return lineItem;
    });
    // ajout
    this.saveProducts(lineItemIdsToUpdate, lineItemsToUpdate)
      .then(() => {
        window.location.reload();
      })
      .catch((error) => {
        console.error("Erreur lors de la mise à jour :", error);
      });
  }

  saveProducts(lineItemIds, lineItemsToUpdate) {
    console.log("@@@lineItemsToUpdate: " + JSON.stringify(lineItemsToUpdate));

    this.errors = {};
    saveLineItems({
      recordTypeName: this.oppRecordTypeName,
      oliIds: lineItemIds,
      lineItems: lineItemsToUpdate
    })
      .then((result) => {
        console.log(JSON.stringify(result));
        if (!result.hasErrors) {
          this.showToast("Success", this.labels.AddProductSuccess, "success");
          this.draftValues = [];
          // Refresh the wire function to reload updated data
          return refreshApex(this.wiredLineItemsResult);
        } else {
          if (result.errorType == "recordError") {
            const formattedErrors = this.convertRecordErrors(result);
            console.log(formattedErrors);
            this.errors = formattedErrors;
          } else if (result.errorType == "tableError") {
            const formattedErrors = this.convertTableErrors(result);
            console.log(formattedErrors);
            this.errors = formattedErrors;
          }
          this.showToast("Error", this.labels.Error, "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", this.labels.Error, "error");
        console.error("Error updating OpportunityLineItems:", error);
      });
  }

  convertRecordErrors(errorResponse) {
    let errors = { rows: {} };

    for (const [recordId, fields] of Object.entries(
      errorResponse.recordErrors
    )) {
      let messages = [];
      let fieldNames = {};

      for (const [field, message] of Object.entries(fields)) {
        messages.push(message);
        fieldNames[field] = message;
      }

      errors.rows[recordId] = {
        title: this.labels.SaveError,
        messages: messages,
        fieldNames: fieldNames
      };
    }

    return errors;
  }

  convertTableErrors(errorResponse) {
    let errors = {};

    for (const [recordId, fields] of Object.entries(
      errorResponse.recordErrors
    )) {
      let messages = [];

      for (const message of Object.values(fields)) {
        messages.push(message);
      }

      errors[recordId] = {
        title: this.labels.SaveTableError,
        messages: messages
      };
    }

    return errors;
  }

  handleChanged(event) {}
  handleCancel(event) {}

  get disableMassButtons() {
    return this.selectedRows.length === 0;
  }

  get disableMassUpdate() {
    return (
      this.disableMassButtons ||
      ((this.selectedAccessType == this.labels.None ||
        !this.selectedAccessType) &&
        (this.selectedDesksPrice < 0 || !this.selectedDesksPrice) &&
        !this.selectedEntryDate &&
        !this.selectedEndDate &&
        this.selectedTotalPrice)
    );
  }

  handleMassDelete(event) {
    const lineItemIdsToDelete = this.selectedRows.map((row) => row.LineItemId);
    this.deleteProducts(lineItemIdsToDelete)
      .then(() => {
        window.location.reload();
      })
      .catch((error) => {
        console.error("error:", error);
      });
  }

  handleAccessTypeChange(event) {
    this.selectedAccessType = event.detail.value;
  }

  handleDesksUnitsChange(event) {
    this.selectedDesksPrice = event.detail.value;
  }

  handleEntryDateChange(event) {
    this.selectedEntryDate = event.detail.value;
  }

  handleEndDateChange(event) {
    this.selectedEndDate = event.detail.value;
  }

  handleTotalPriceChange(event) {
    this.totalPrice = event.detail.value;
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant // success, error, warning, info
    });
    this.dispatchEvent(event);
  }

  /* connectedCallback() {
    console.log("Label value:", ListPriceSum);
    console.log("Label value:", AverageDeskPrice);
    console.log("Label value:", Desks);
    console.log("Label value:", MonthlyPrice);
    console.log("Label value:", QuantitySum);
    console.log("Label value:", TotalPriceOther);
    console.log("Label value:", ListPriceAdjustment);
    console.log("Label value:", TemporaryProductCheck);
  } */
}