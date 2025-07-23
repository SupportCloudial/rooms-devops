import { LightningElement, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getContracts from '@salesforce/apex/OpportunityProductController.getContracts';
import { refreshApex } from '@salesforce/apex';


import Name from '@salesforce/label/c.PackageBuilderTbl_Name';
import AccessType from '@salesforce/label/c.PackageBuilder_AccessType';
import EndDate from '@salesforce/label/c.PackageBuilderTbl_EndDate';
import EntryDate from '@salesforce/label/c.PackageBuilderTbl_EntryDate';
import Availability from '@salesforce/label/c.PackageBuilder_Availability';
import AvailableStatus from '@salesforce/label/c.PackageBuilder_AvailableStatus';
import PartlyAvailableStatus from '@salesforce/label/c.PackageBuilder_PartlyAvailableStatus';
import NotAvailableStatus from '@salesforce/label/c.PackageBuilder_NotAvailableStatus';

 
export default class ShowAvailabilityModal extends LightningModal {
    labels = {
        Name,
        AccessType,
        EntryDate,
        EndDate,
        Availability,
        AvailableStatus,
        PartlyAvailableStatus,
        NotAvailableStatus,
    }

    @api header;
    @api content;
    @api recordId; //opp record id
    // Data is passed to api properties via .open({ options: [] })
    @api btnOptions = [];
    contracts = [];

    connectedCallback() {
        getContracts({oppId:this.recordId})
        .then(result => {
            this.contracts = result.map(prod => {
                return {
                    ...prod,
                    AvailabilityIcon:this.getProductAvailabilityIcon(prod.Availability),
                    ContractLink: this.getLink(prod.ContractId)
                };
            });
        })
        .catch((error) => {
            console.error('Error fetching contracts:', JSON.stringify(error));
        });
    }

    getProductAvailabilityIcon(availability){
        let icon;

        switch (availability) {
            case this.labels.PartlyAvailableStatus:
                icon = '🟡';
                break;
            case this.labels.NotAvailableStatus:
                icon = '🔴';
                break;
            default:
        }
        return icon;
    }

    getLink(contractId){
        return '/' + contractId;
    }

    //create custom labels for the columns:
    columns = [
        { label: this.labels.Name, fieldName: 'Name' },
        { label: this.labels.Availability, fieldName: 'AvailabilityIcon' }, 
        {
            label: 'Contract Related',
            fieldName: 'ContractLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'ContractName' }, target: '_blank' }
        },
        { label: this.labels.AccessType, fieldName: 'AccessType' },
        { label: this.labels.EntryDate, fieldName: 'EntryDate', type: 'date-local', typeAttributes: { dateStyle: 'short', day: "2-digit", month: "2-digit", year: "numeric", timeZone: "UTC"} },
        { label: this.labels.EndDate, fieldName: 'EndDate', type: 'date-local', typeAttributes: { dateStyle: 'short', day: "2-digit", month: "2-digit", year: "numeric", timeZone: "UTC"} },
    ];

    handleOptionClick(e) {
        const { target } = e;
        const { id } = target.dataset;
        // this.close() triggers closing the modal
        // the value of `id` is passed as the result
        console.log('id: ' + id);
        
        this.close(id);
    }
}