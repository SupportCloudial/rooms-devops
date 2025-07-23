import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';
 
export default class AddOppProductModal extends LightningModal {
    @api header;
    @api content;
    @api recordId;
    // Data is passed to api properties via .open({ options: [] })
    @api btnOptions = [];

    handleOptionClick(e) {
        const { target } = e;
        const { id } = target.dataset;
        // this.close() triggers closing the modal
        // the value of `id` is passed as the result
        console.log('id: ' + id);
        
        this.close(id);
    }

    handleAddProducts(e){
        this.close('addProducts');
    }
}