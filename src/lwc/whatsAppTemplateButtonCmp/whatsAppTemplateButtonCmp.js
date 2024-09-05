import { LightningElement,api } from 'lwc';
export default class WhatsAppTemplateButtonCmp extends LightningElement {
	@api buttonData = {};
	@api indx;
	actionTypes = [
		{
				label:'Call Phone Number',
				value:'Call Phone Number'
		},
		{
				label:'Visit website',
				value:'Visit website'
		},
		{
				label:'Copy offer code',
				value:'Copy offer code'
		}
	];
	get isCustomButtonType(){
		return this.buttonData.type == 'QUICK_REPLY';
	}
	get isPhoneButtonType(){
		return this.buttonData.type == 'PHONE_NUMBER';
	}
	
	get isUrlButtonType(){
		return this.buttonData.type == 'URL';
	}
	
	get isCopyCodeButtonType(){
		return this.buttonData.type == 'COPY_CODE';
	}
		
	handleTextChange(event) {
		var data = JSON.parse(JSON.stringify(this.buttonData));
		data[event.target.dataset.name] = event.detail.value;
		this.buttonData = data;
    }
		
	handleOnBlur(){
		this.dispatchEvent(new CustomEvent('buttonchange', {
			detail: {
				buttonData: this.buttonData,
				indx: this.indx
			}
		}));
	}
}