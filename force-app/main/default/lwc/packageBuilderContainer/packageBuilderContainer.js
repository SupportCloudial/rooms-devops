import { api, LightningElement } from 'lwc';
import addOppProductModal from "c/addOppProductModal";

import packagebuilder_title from '@salesforce/label/c.PackageBuilder_Title';
import packagebuilder_add_products from '@salesforce/label/c.PackageBuilder_AddProducts';
import packagebuilder_cancel from '@salesforce/label/c.PackageBuilder_Cancel';

export default class PackageBuilderContainer extends LightningElement {

    labels = {
        packagebuilder_title,
        packagebuilder_add_products,
        packagebuilder_cancel
    };


    @api recordId;
    @api title = this.labels.packagebuilder_title;       
    @api buttonLabel = this.labels.packagebuilder_add_products;  

    handleAddProducts(event){
        event.stopPropagation();

        addOppProductModal.open({
            btnOptions: [
                { val: 'Cancel', label: this.labels.packagebuilder_cancel,  variant:'natural'},
                //{ val: 'AddProducts', label: 'Add Products and Close',  variant:'brand'},
            ],
            content:'',
            header:this.labels.packagebuilder_add_products,
            size:'medium',
            recordId: this.recordId

        }).then((result) => {
            if(result == 'addProducts'){
                const tableComponent = this.template.querySelector('c-package-builder-table');
                if (tableComponent) {
                    tableComponent.refreshProductsTable();
                }
            }else if(result == 'Close'){
                
            }
        });
    }
}