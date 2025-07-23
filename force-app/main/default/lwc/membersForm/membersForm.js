import { LightningElement, wire , track, api  } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getNumberOfMembers from '@salesforce/apex/OpportunityMembersController.getNumberOfMembers';
import saveContacts from '@salesforce/apex/OpportunityMembersController.saveContacts';
import roomsLogo from '@salesforce/resourceUrl/rooms_logo';
import FieldRequired from '@salesforce/label/c.FieldRequired';
import PhoneNotValid from '@salesforce/label/c.PhoneNotValid';
import NameNotValid from '@salesforce/label/c.NameNotValid';
import EmailNotValid from '@salesforce/label/c.EmailNotValid';
import EmailExist from '@salesforce/label/c.EmailExist';
import Firstname from '@salesforce/label/c.FirstName';
import LastName from '@salesforce/label/c.LastName';
import NumberMembers from '@salesforce/label/c.NumberMembers';
import Phone from '@salesforce/label/c.Phone';
import Email from '@salesforce/label/c.Email';
import Birthdate from '@salesforce/label/c.Birthdate';
import ButtonSave from '@salesforce/label/c.ButtonSave';
import MessageAfter1 from '@salesforce/label/c.MessageAfter1';
import MessageAfter2 from '@salesforce/label/c.MessageAfter2';
import yetEnregistred from '@salesforce/label/c.yetEnregistred';
import ToastRequiredField from '@salesforce/label/c.ToastRequiredField';
import Description_0 from '@salesforce/label/c.Description_0';
import Description_1 from '@salesforce/label/c.Description_1';
import Description_2 from '@salesforce/label/c.Description_2';
import Description_3 from '@salesforce/label/c.Description_3';
import Description_4 from '@salesforce/label/c.Descritpion_4';
import LANG from '@salesforce/i18n/lang';

import FORM_FACTOR from '@salesforce/client/formFactor';
 
export default class MembersForm extends LightningElement {
    logoUrl = roomsLogo;
    numberOfMembers;
    @track members = [];
    memberIsNotEmpty = false;
    //contractId = '800J70000005EaYIAU';
    contractId;
    validatedEmails = [];
    noValidatedEmails = [];
    showToast = false;
    timeToast = 4000;
    isMobile;
    accountId;
    sendContact = false;
    membersRegistred;
    language;
    @track ifHebrew = false;
    isButtonDisabled = false;

    toastMessage = '';
    toastTheme = '';

    customLabels = {
        FieldRequired,
        Email,
        Firstname,
        LastName,
        Phone,
        NumberMembers,
        Birthdate,
        Description_4,
        ButtonSave,
        MessageAfter1,
        MessageAfter2,
        yetEnregistred,
        ToastRequiredField,
        Description_3,
        Description_2,
        Description_1,
        Description_0,
    };

    handleShowToast(message, theme) {
        this.showToast = true;
        this.toastMessage = message;
        this.toastTheme = theme;
        setTimeout(() => {
            this.showToast = false;
          }, this.timeToast);
    }

    handleCloseToast(){
        this.showToast = false;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.handleFormFactor();
        if (currentPageReference) {
            this.contractId = currentPageReference.state?.contractId;
            this.language = LANG;
            if (this.language == 'iw') {
                this.ifHebrew = true;
            } else {
                this.language =='en-US';
            }
            this.handleGetNumberOfMember();
       }
    }

    get getCardStyle() {
        return this.ifHebrew ? 'overflow: hidden; width: 100%; direction: rtl;' : 'overflow: hidden; width: 100%;';
    }

    get getRead() {
        if (this.ifHebrew && (FORM_FACTOR === "Large" || FORM_FACTOR === "Medium")){
            return 'text-align: right';
        } else if(!this.ifHebrew && FORM_FACTOR === "Small"){
            return 'float: left;';
        }
    }
    get getButton() {
        return this.ifHebrew ?  'text-align: left; margin-top: 20px; margin-left: 20px;' : 'text-align: right; margin-top: 20px; margin-right: 20px;';
    }
    
    handleFormFactor() {
        if (FORM_FACTOR === "Large") {
        } else if (FORM_FACTOR === "Medium") {
        } else if (FORM_FACTOR === "Small") {
            this.isMobile = "true";
        }
    }

    handleGetNumberOfMember(){
        getNumberOfMembers({ contractsId: this.contractId }) 
        .then(con => {
            this.numberOfMembers = con != null && con.Opportunities.length > 0 ? con.Opportunities[0].Number_of_members__c : console.log('error');
            this.accountId = con != null ? con.Opportunities[0].AccountId : console.log('error');
            this.membersRegistred = con != null ? con.Members_Registred__c : console.log('error');

            this.memberIsNotEmpty = true;

            if (this.membersRegistred == false ) {
                this.createContacts();
                this.sendContact = false;
            } else {
                this.sendContact = false;
            }
        })
        .catch(error => {
            // Gérer les erreurs
        });
    }

    handleDelete(event) {

        if(this.members.length > 1){
          const index = event.target.dataset.index;
          const temp = this.members;
          temp.splice(index , 1);
          this.members = temp;
          this.updateIndexes();
        } else {
            // Si this.members.length est égal à 1 ou 0, ne rien faire ici
        // Le bloc else est laissé vide
        }
    }

    updateIndexes() {
        for (let i = 0; i < this.members.length; i++) {
            this.members[i].Index = i + 1;  
        }
        this.numberOfMembers = this.members.length;
    }

    createContacts() {
        this.members = [];
        for (let i = 1; i <= this.numberOfMembers; i++) {
            let line = { "Email": "", "FirstName": "", "MobilePhone": "", "LastName": "", "Birthdate": ""};
            line.Index = i;
            line.AccountId = this.accountId;
            this.members.push(line);
        }
    }

    handleSave(event) {
        this.members[event.target.dataset.index][event.target.name]=event.target.value;   
    }

    checkFormValidity() {
        let isValid = true;
        let emailSet = new Set(); // to check the duplicate
        const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
        const phoneRegex = /^[+]{0,1}\d{8,14}$/;
        const nameRegex = /^[A-Za-z ]+$/;
        //const nameRegexHebrew = /^[\u0590-\u05FF ]+$/;
    
        for (let i = 0; i < this.members.length; i++) {
            let member = this.members[i];
    
    
            if (!member.Email) {
                isValid = false;
                this.displayFieldError(i, 'EmailError', FieldRequired);
            } else {
                if (emailSet.has(member.Email.toLowerCase())) {
                    isValid = false;
                    this.displayFieldError(i, 'EmailError', EmailExist);
                } else {
                    emailSet.add(member.Email.toLowerCase());
                }
    
                if (!emailRegex.test(member.Email)) {
                    isValid = false;
                    this.displayFieldError(i, 'EmailError', EmailNotValid);
                }
            }
    
            if (!member.MobilePhone) {
                isValid = false;
                this.displayFieldError(i, 'PhoneError', FieldRequired);
            } else {
                if (!phoneRegex.test(member.MobilePhone)) {
                    isValid = false;
                    this.displayFieldError(i, 'PhoneError', PhoneNotValid);
                }
            }
    
            if (!member.LastName) {
                isValid = false;
                this.displayFieldError(i, 'LastNameError', FieldRequired);
            } else {
                if (!nameRegex.test(member.LastName)) {
                    isValid = false;
                    this.displayFieldError(i, 'LastNameError', NameNotValid);
                }

            }
    
            if (!member.FirstName) {
                isValid = false;
                this.displayFieldError(i, 'FirstNameError', FieldRequired);
            } else {
                if (!nameRegex.test(member.FirstName)) {
                    isValid = false;
                    this.displayFieldError(i, 'FirstNameError', NameNotValid);
                }
            }
    
            const rowElements = this.template.querySelectorAll(`[data-row="${i}"]`);
            rowElements.forEach(element => {
                element.classList.add('error-row');
            });
        }
    
        if (isValid) {
            this.saveContacts(this.members);
            this.isButtonDisabled = true;
        }
    }    

    displayFieldError(index, fieldName, errorMessage) {
        const fieldElement = this.template.querySelector(`[data-index="${index}"][data-field="${fieldName}"]`);
        fieldElement.style.display = 'block';
        fieldElement.textContent = errorMessage;
    }
    
    saveContacts(contactsToSave){
        saveContacts({ contacts: contactsToSave, idContract: this.contractId } )
            .then(result => { 
                if (result === 'Success') {
                    this.sendContact = true; // Activez la page pour la confirmation en cas de succès
                } else {
                    // Gérez l'erreur en cas d'échec
                   // this.displayFieldError(i, 'EmailError', EmailExist);
                    this.handleShowToast('An error occurred while saving contacts.', 'error');
                }
            })
            .catch(error => {
                console.error(error);
                this.handleShowToast('An unexpected error occurred.', 'error');
            });
    }

    handleRecordCreation() {
        this.template.querySelectorAll('lightning-input').forEach(input => {
            input.classList.remove('error');
        });
        this.template.querySelectorAll('.error-message').forEach(errorMessage => {
            errorMessage.textContent = '';
            errorMessage.style.display = 'none';
        });
        this.checkFormValidity();
    }
}