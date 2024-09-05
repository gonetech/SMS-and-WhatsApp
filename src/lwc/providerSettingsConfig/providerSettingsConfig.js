import { LightningElement, track, wire } from 'lwc';
import getProviderSettings from '@salesforce/apex/ProviderSettingsConfigController.getProviderSettings';
import upsertProviderSetting from '@salesforce/apex/ProviderSettingsConfigController.upsertProviderSetting';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProviderSettingsList extends LightningElement {
    @track providerSettingList = [];
    @track error;
    isShowModal = false;
    selectedRecordId = '';
    isPermissionError = false;

    @track providerSettings = {
        id: '',
        name: '',
        accountSID: '',
        applicationId: '',
        appSecretKey: '',
        authToken: '',
        channel: '',
        messagingServiceSID: '',
        phoneNumberId: '',
        serviceProviderName: '',
        twilioPhoneNumber: '',
        whatsappBusinessId: '',
        isActive: false
    };

    wiredResult;

    get isSmsChannel() {
        return this.providerSettings.channel == 'SMS';
    }

    get isWhatsAppChannel() {
        return this.providerSettings.channel == 'WhatsApp';
    }
    
    get modalHeader(){
        return this.providerSettings.channel;
    }
    
    channelOptions = [
        { label: 'SMS', value: 'SMS' },
        { label: 'WhatsApp', value: 'WhatsApp' }
    ];

		@wire(getProviderSettings)
		wiredSettings(result) {
				this.wiredResult = result;
				let sms = {
						name: 'Twilio',
						accountSID: '',
						applicationId: '',
						appSecretKey: '',
						authToken: '',
						channel: 'SMS',
						messagingServiceSID: '',
						phoneNumberId: '',
						serviceProviderName: 'Twilio',
						twilioPhoneNumber: '',
						whatsappBusinessId: '',
						isActive: false
				};
				let whatsApp = {
						name: 'Meta',
						accountSID: '',
						applicationId: '',
						appSecretKey: '',
						authToken: '',
						channel: 'WhatsApp',
						messagingServiceSID: '',
						phoneNumberId: '',
						serviceProviderName: 'Meta',
						twilioPhoneNumber: '',
						whatsappBusinessId: '',
						isActive: false
				};
				if (result.data) {
						this.providerSettingList = [];
						let providerSettingList = result.data;
						let smsRec = providerSettingList.find(record => record.channel == 'SMS');
						let whatsAppRec = providerSettingList.find(record => record.channel == 'WhatsApp');
						if(!smsRec){
								this.providerSettingList = [...this.providerSettingList,sms];
						} else {
								this.providerSettingList = [...this.providerSettingList,smsRec];
						}
						if(!whatsAppRec){
								this.providerSettingList = [...this.providerSettingList,whatsApp];
						} else {
								this.providerSettingList = [...this.providerSettingList,whatsAppRec];
						}
						this.error = undefined;
				} else if (result.error) {
						this.error = result.error.body.message;
						if(this.error == 'User don\'t have the required permissions to access this feature.' || this.error == 'You do not have access to the Apex class named \'ProviderSettingsConfigController\'.'){
								this.isPermissionError = true;
						}
						this.providerSettingList = [];
				} else {
						this.providerSettingList = [...this.providerSettingList,sms,whatsApp];
				}
		}

    handleInputChange(event) {
        const field = event.target.dataset.id;
        if(field == 'isActive'){
            this.providerSettings[field] = event.target.checked;
        } else {
            this.providerSettings[field] = event.target.value;
        }
    }

    handleClickNew(){
        this.isShowModal = true;
    }

    handleClose(){
        this.isShowModal = false;
        this.selectedRecordId = '';
        this.providerSettings = {
            id: '',
            name: '',
            accountSID: '',
            applicationId: '',
            appSecretKey: '',
            authToken: '',
            channel: '',
            messagingServiceSID: '',
            phoneNumberId: '',
            serviceProviderName: '',
            twilioPhoneNumber: '',
            whatsappBusinessId: '',
            isActive: false
        };
    }

    handleRowClick(event) {
        const id = event.currentTarget.getAttribute('data-id');
        let rec = JSON.parse(JSON.stringify(this.providerSettingList.find(record => record.channel == id)));
        rec['appSecretKey'] = '';
        rec['authToken'] = '';
        this.providerSettings = { ...rec };
        this.isShowModal = true;
    }

    handleSave() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid){
            upsertProviderSetting({ providerSettingStr: JSON.stringify(this.providerSettings) })
                .then(() => {
                this.isShowModal = false;
                return Promise.all([
                    refreshApex(this.wiredResult),
                ]);
            })
            .then(() => {
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Settings updated successfully.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            })
            .catch(error => {
                console.error(error);
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : error.message || 'Unknown error',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
        } else {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Required fields are missing.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
    }
}