import { LightningElement, api, track, wire } from 'lwc';

import getProducts from '@salesforce/apex/AddOppProductController.getProductsByOppLocation';
import addProductsToOpp from '@salesforce/apex/AddOppProductController.addProductsToOpp';

import AddProducts from '@salesforce/label/c.PackageBuilder_AddProducts';
import Name from '@salesforce/label/c.AddProductsTbl_Name';
import Floor from '@salesforce/label/c.AddProductsTbl_Floor';
import DeskCount from '@salesforce/label/c.AddProductsTbl_DeskCount';
import DeskUnitPrice from '@salesforce/label/c.AddProductsTbl_DeskUnitPrice';
import ListPrice from '@salesforce/label/c.AddProductsTbl_ListPrice';
import Window from '@salesforce/label/c.AddProductsTbl_Window';
import State from '@salesforce/label/c.AddProductsTbl_State';
import None from '@salesforce/label/c.PackageBuilder_None';
import DesksTooltip from '@salesforce/label/c.AddProducts_DesksTooltip';
import Success from '@salesforce/label/c.AddProducts_Success';
import Error from '@salesforce/label/c.AddProducts_Error';
import Saving from '@salesforce/label/c.AddProducts_Saving';
import Type from '@salesforce/label/c.AddProductsFltr_Type';
import TypePH from '@salesforce/label/c.AddProductsFltr_TypePH';
import SubType from '@salesforce/label/c.AddProductsFltr_SubType';
import SubTypePH from '@salesforce/label/c.AddProductsFltr_SubTypePH';
import DesksNum from '@salesforce/label/c.AddProductsFltr_DesksNum';
import NameSearch from '@salesforce/label/c.AddProductsFltr_NameSearch';
import NameSearchPH from '@salesforce/label/c.AddProductsFltr_NameSearchPH';
import Availability from '@salesforce/label/c.PackageBuilder_Availability';
import AvailableStatus from '@salesforce/label/c.PackageBuilder_AvailableStatus';
import PartlyAvailableStatus from '@salesforce/label/c.PackageBuilder_PartlyAvailableStatus';
import NotAvailableStatus from '@salesforce/label/c.PackageBuilder_NotAvailableStatus';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getRecord } from 'lightning/uiRecordApi';

import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
const FIELDS = ['Opportunity.RecordTypeId'];
 
export default class AddOppProduct extends LightningElement {
    
    labels = {
        AddProducts,
        Name,
        Floor,
        DeskCount,
        DeskUnitPrice,
        ListPrice,
        Window,
        State,
        None,
        DesksTooltip,
        Success,
        Error,
        Saving,
        Type,
        TypePH,
        SubType,
        SubTypePH,
        DesksNum,
        NameSearch,
        NameSearchPH,
        Availability,
        AvailableStatus,
        PartlyAvailableStatus,
        NotAvailableStatus
    };
    
    
    @api recordId;
    recordTypeId;
    isLoading = false;

    @track initialProducts = [];
    @track filteredProducts = [];
    @track selectedRows = [];
    selectedRowIds = [];

    // Filters
    @track typeOptions = [];
    @track subTypeOptions = [];
    selectedType = '';
    selectedSubType = '';
    searchKey = '';

    minDeskVal = 0;
    maxDeskVal = 30;
    deskVal = this.maxDeskVal;
    showPlus = true;

    //create custom labels for the columns:
    columns = [
            { label: this.labels.Name, fieldName: 'Name' },
            //{ label: this.labels.Availability, fieldName: 'Availability' },
            //{ label: this.labels.Availability, type: 'button', cellAttributes: { alignment: 'center' }, typeAttributes: {label: { fieldName: 'AvailabilityIcon' }, name: 'availability', variant:'base', title:{ fieldName: 'Availability' }}, initialWidth: 45},
            { label: this.labels.Floor, fieldName: 'Floor' },
            { label: this.labels.DeskCount, fieldName: 'CapacityDesks', type: 'number', cellAttributes: { alignment: 'left' } },
            { label: this.labels.DeskUnitPrice, fieldName: 'CalculatedPrice', type: 'number', cellAttributes: { alignment: 'left' } },
            { label: this.labels.ListPrice, fieldName: 'UnitPrice', type: 'currency', cellAttributes: { alignment: 'left' } },
            { label: this.labels.Window, fieldName: 'Window', type: 'boolean' },
            { label: this.labels.State, fieldName: 'State' },
        ];

    @wire(getProducts, {oppId:'$recordId'})
    wiredProducts({ error, data }) {
        if (data) {
            this.initialProducts = data;
            this.filteredProducts = data;

        } else if (error) {
            console.error('Error fetching products:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.recordTypeId = data.fields.RecordTypeId.value;
            console.log('RecordTypeId:', this.recordTypeId);
        } else if (error) {
            console.error('Error fetching opportunity record:', error);
        }
    }

    // Get picklist values by record type
    @wire(getPicklistValuesByRecordType, {
        objectApiName: OPPORTUNITY_OBJECT,
        recordTypeId: '$recordTypeId'
    })
    picklistValues({ error, data }) {
        if (data) {

            this.typeOptions = this.parsePicklist(data.picklistFieldValues.Product_Type__c);
            this.typeOptions = [
                { label: this.labels.None, value: '' },
                ...this.typeOptions
            ];
            this.allSubTypeOptions = data.picklistFieldValues.Product_Sub_Type__c.controllerValues;
            this.subTypeOptionsMap = data.picklistFieldValues.Product_Sub_Type__c.values;
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    parsePicklist(picklistField) {
        return picklistField.values.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.selectedSubType = ''; // Reset sub type on type change

        // Filter Sub Types based on selected Type
        const controllerValue = this.allSubTypeOptions[this.selectedType];
        if (controllerValue !== undefined && controllerValue !== '') {
            this.subTypeOptions = this.subTypeOptionsMap
                .filter(opt => opt.validFor.includes(controllerValue))
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));

                this.subTypeOptions = [
                    { label: this.labels.None, value: '' },
                    ...this.subTypeOptions
                ];
        } else {
            this.subTypeOptions = [];
        }

        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRowIds;
        this.filterProducts();
    }

    handleSubTypeChange(event) {
        this.selectedSubType = event.detail.value;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRowIds;
        this.filterProducts();
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.detail.value.toLowerCase();
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRowIds;
        this.filterProducts();
    }

    filterProducts() {
        this.filteredProducts = this.initialProducts.filter(product => {
            const typeMatch = this.selectedType ? product.ProductType === this.selectedType : true;
            const subTypeMatch = this.selectedSubType ? product.ProductSubType === this.selectedSubType : true;
            const nameMatch = this.searchKey ? product.Name.toLowerCase().includes(this.searchKey) : true;
            const desksMatch  = this.deskVal && this.deskVal < this.maxDeskVal ? product.CapacityDesks <= this.deskVal : true; 

            return typeMatch && subTypeMatch && nameMatch && desksMatch;
        });
    }

    get disableSubTypeOptions(){
        return this.subTypeOptions.length == 0;
    }
    
    get selectedRowIdsArray() {
        return this.selectedRowIds;
    }

    get sliderToolTip() {
        const tooltip = this.formatLabel(this.labels.DesksTooltip, this.deskVal);
        return tooltip;//'Show products from 0 and up to ' + this.deskVal + ' desks. Includes products without desks. Slide to 30+ to show all products';
    }

    handleRowSelection(event) {
        /*const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows;*/

        //console.log('Selected Row Ids Set:', this.selectedRows);

        let updatedItems = [];
        // List of selected items we maintain.
        let selectedItems = [...this.selectedRowIds];
        // List of items currently loaded for the current view.
        let loadedItems = [];

        this.filteredProducts.map((ele) => {
            loadedItems.push(ele.Id);
        });

        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((ele) => {
                updatedItems.push(ele.Id);
            });
            // Add any new items to the selectedRowIds list
            updatedItems.forEach((id) => {
                if (!selectedItems.includes(id)) {
                    selectedItems.push(id);
                }
            });
        }

        loadedItems.forEach((id) => {
            if (selectedItems.includes(id) && !updatedItems.includes(id)) {
                // Remove any items that were unselected.
                selectedItems.splice(selectedItems.indexOf(id), 1);
            }
        });

        this.selectedRowIds = [...selectedItems];
        console.log('selectedRowIds:', this.selectedRowIds);
    }

    handleDeskValChange(event){
        this.deskVal = event.detail.value;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRowIds;
        if(this.deskVal == this.maxDeskVal){
            this.showPlus = true;
        }else{
            this.showPlus = false;
        }
        this.filterProducts();
    }

    get disableAddProducts(){
        return this.selectedRowIds.length == 0 || this.isLoading == true;
    }

    handleAddProducts() {
        console.log('productEntryIds:', this.selectedRowIds);

        if(this.selectedRowIds.length > 0){
            this.isLoading = true;
            addProductsToOpp({ productEntryIds:this.selectedRowIds, opportunityId: this.recordId })
            .then(resultMessage => {
                if(resultMessage != ''){
                    this.showToast('Error', resultMessage, 'error');
                    console.log('Something went wrong:', resultMessage);
                }else{
                    this.showToast('Success', this.labels.Success, 'success');
                    this.dispatchEvent(new CustomEvent('addproducts'));
                }
                
                // Show Toast or do something else
            })
            .catch(error => {
                // Error handling
                this.showToast('Error', this.labels.Error, 'error');
                console.log('Something went wrong:', resultMessage);
            })
            .finally(() => {
                this.isLoading = false; // Hide spinner after promise resolves
            });
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // success, error, warning, info
        });
        this.dispatchEvent(event);
    }

    formatLabel(label, ...values) {
        return label.replace(/{(\d+)}/g, (match, index) => values[index] || '');
    }
}