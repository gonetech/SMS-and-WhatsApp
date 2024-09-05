import { LightningElement, track, wire, api } from 'lwc';
import getAllObject from '@salesforce/apex/WhatsAppTemplateCreationController.getAllObject';
import getAllfields from '@salesforce/apex/WhatsAppTemplateCreationController.getAllfields';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import save from '@salesforce/apex/WhatsAppTemplateCreationController.handleSave';
import handleEdit from '@salesforce/apex/WhatsAppTemplateCreationController.handleEdit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

const fields = [
		'connectsocial__Message_Template__c.connectsocial__Template_Name__c',
		'connectsocial__Message_Template__c.connectsocial__Channel__c',
		'connectsocial__Message_Template__c.connectsocial__Body__c',
		'connectsocial__Message_Template__c.connectsocial__Header__c',
		'connectsocial__Message_Template__c.connectsocial__Footer__c',
		'connectsocial__Message_Template__c.connectsocial__Button__c',
		'connectsocial__Message_Template__c.connectsocial__WhatsApp_Template_ID__c'
];

const FILE_SIZE_LIMITS = {
    audio: 16 * 1024 * 1024, 
    document: 100 * 1024 * 1024, 
    image: 5 * 1024 * 1024, 
    sticker: 100 * 1024, 
    video: 16 * 1024 * 1024 
};

export default class WhatsAppTemplateCreationCmp extends LightningElement {
		channelOptions = [
				{ label: "SMS", value: "SMS" },
				{ label: "WhatsApp", value: "WhatsApp" }
		];
		headerOptions = [
				{ label: "None", value: "none" },
				{ label: "Text", value: "Text" },
				{ label: "Image", value: "Image" },
				{ label: "Video", value: "Video" },
				{ label: "Document", value: "Document" }
		];
		@api recordId;
		@track fileName;
		@track fileSizeWarning = '';
		@track objectOptions = [];
		@track fieldOptions = [];
		@track templateData = {
				header: 'none',
				channel: null,
				objectName: null,
				bodyText: '',
				footerText: '',
				headerText: '',
				buttons: [],
				headerMedia: {}
		};
		bodyVarCount = 1;
		showFieldPopup = false;
		isLoading = false;

		get cardTitle(){
				return this.recordId ? 'Edit Template' : 'Create Template';
		}

		get isShowHeaderText() {
				return this.templateData.header === 'Text';
		}

		get isShowHeaderMedia() {
				return this.templateData.header === 'Image' || this.templateData.header === 'Video' || this.templateData.header === 'Document';
		}

		get isShowButtons() {
				return this.templateData.buttons.length > 0;
		}

		get isWhatsApp() {
				return this.templateData.channel === 'WhatsApp';
		}

		get isShowQuickReply() {
				return this.templateData.buttons.some(button => button.isQuickReply);
		}

		get isShowCalltoAction() {
				return this.templateData.buttons.some(button => !button.isQuickReply);
		}


		connectedCallback() {
				this.setCSSProperties();
				this.fetchAllObjects();
				if (this.recordId) {
						this.retrieveTemplateDetails();
				}
		}

		setCSSProperties() {
				const css = document.body.style;
				css.setProperty('--slds-c-card-spacing-block-start', '20px');
				css.setProperty('--slds-c-card-spacing-block-end', '20px');
				css.setProperty('--slds-c-card-spacing-inline-start', '20px');
				css.setProperty('--slds-c-card-spacing-inline-end', '20px');
				css.setProperty('--lwc-fontSize5', '20px');
		}

		fetchAllObjects() {
				getAllObject().then(data => {
						this.objectOptions = Object.keys(data).map(key => ({ label: key, value: data[key] }));
				}).catch(() => {
						this.showToast('Error', 'Failed to fetch objects', 'error');
				});
		}

		handleChange(event) {
				const { name } = event.target.dataset;
				this.templateData[name] = event.detail.value;
				if (name === 'objectName') {
						this.fetchAllFields(event.detail.value);
				}
		}

		fetchAllFields(objectName) {
				getAllfields({ objectName }).then(data => {
						this.fieldOptions = Object.keys(data).map(key => ({ label: key, value: data[key] }));
				}).catch(() => {
						this.showToast('Error', 'Failed to fetch fields', 'error');
				});
		}

		handleButtonMenuSelect(event){
				if(event.detail.value == 'custom'){
						this.templateData.buttons.push({
								type:"QUICK_REPLY",
								text:'',
								isQuickReply: true
						});
				} else if(event.detail.value == 'website'){
						this.templateData.buttons.push({
								type:"URL",
								text:'',
								url:'',
								isQuickReply: false
						});

				} else if(event.detail.value == 'phoneNumber'){
						this.templateData.buttons.push({
								type:"PHONE_NUMBER",
								text:'',
								phone_number:'',
								isQuickReply: false
						});

				} else if(event.detail.value == 'offerCode'){
						this.templateData.buttons.push({
								type:"COPY_CODE",
								text:'Copy offer code',
								example:'',
								isQuickReply: false
						});
				}
		}

		handleMenuSelect(event){
				var ta = this.template.querySelector('lightning-textarea');
				ta.setRangeText('{!'+event.detail.value+'}');
		}

		handleFilesChange(event){
			this.fileName = '';
			const file = event.target.files[0];
			if (file) {
				const fileType = this.getFileType(file.type); 
				const fileSizeLimit = this.getFileSizeLimit(file.type);
				if (file.size > fileSizeLimit) {
					this.fileSizeWarning = `The file exceeds the maximum size limit for ${fileType}. Max allowed: ${this.formatFileSize(fileSizeLimit)}. Please choose another file.`;
					return; 
				} else {
					this.fileSizeWarning = ''; 
				}

				const reader = new FileReader();
				reader.onload = () => {
					const fileData = reader.result.split(',')[1]; 
					this.templateData.headerMedia = {
						fileName: file.name,
						fileSize: file.size,
						fileType: file.type,
						fileData: fileData 
					};
					this.fileName = file.name;
				};
				reader.readAsDataURL(file);
			}
		}

		getFileSizeLimit(fileType) {
			if (fileType.includes('audio/')) {
				return FILE_SIZE_LIMITS.audio;
			} else if (fileType.includes('document/')) {
				return FILE_SIZE_LIMITS.document;
			} else if (fileType.includes('image/')) {
				return FILE_SIZE_LIMITS.image;
			} else if (fileType.includes('sticker/')) {
				return FILE_SIZE_LIMITS.sticker;
			} else if (fileType.includes('video/')) {
				return FILE_SIZE_LIMITS.video;
			} else {
				return FILE_SIZE_LIMITS.document; 
			}
		}

		getFileType(fileMimeType) {
			if (fileMimeType.startsWith('audio/')) {
				return 'audio';
			} else if (fileMimeType.startsWith('application/')) {
				return 'document';
			} else if (fileMimeType.startsWith('image/')) {
				return 'image';
			} else if (fileMimeType.startsWith('video/')) {
				return 'video';
			} else {
				return 'file'; 
			}
		}

		formatFileSize(size) {
			if (size >= 1024 * 1024) {
				return `${(size / (1024 * 1024)).toFixed(2)} MB`;
			} else if (size >= 1024) {
				return `${(size / 1024).toFixed(2)} KB`;
			}
			return `${size} bytes`;
		}
		replacePlaceholders(text) {
				const pattern = /{![^{}]+}/g;
				let index = 1;
				const result = text.replace(pattern, function() {
						return `{{${index++}}}`;
				});
				this.bodyVarCount = index;
				return result;
		}
		@wire(getRecord, { recordId: '$recordId', fields })
		wiredRecord({ error, data }) {
				if (data) {
						this.populateTemplateData(data);
				} else if (error) {
						this.showToast('Error', 'Failed to fetch record', 'error');
				}
		}

		populateTemplateData(record) {
				this.templateData.templateName = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Template_Name__c');
				this.templateData.channel = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Channel__c');
				this.templateData.bodyText = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Body__c');
				this.templateData.headerText = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Header__c');
				this.templateData.footerText = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Footer__c');
				this.templateData.TemplateId = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__WhatsApp_Template_ID__c');
				const buttonData = getFieldValue(record, 'connectsocial__Message_Template__c.connectsocial__Button__c');
				this.templateData.buttons = buttonData ? JSON.parse(buttonData) : [];
		}

		handleSave() {
				this.isLoading = true;
				const ta = this.template.querySelector('lightning-textarea');
				this.templateData.formattedBodyText = this.replacePlaceholders(ta.value);

				if(this.bodyVarCount > 1){
						let exampleVar = {
								body_text:[]
						};
						let bodyTextVar = [];
						for(let i=1;i < this.bodyVarCount;i++){
								bodyTextVar.push('Test '+i);
						}
						exampleVar.body_text.push(bodyTextVar);
						this.templateData['example'] = exampleVar;
				}
				const buttons = JSON.parse(JSON.stringify(this.templateData.buttons));
				buttons.forEach(button => delete button.isQuickReply);
				this.templateData.buttons = buttons;
				const templateDataStr = JSON.stringify(this.templateData);
				if (this.recordId) {
						handleEdit({templateDataStr: JSON.stringify(this.templateData), waTemplateId:this.templateData.TemplateId , templateId: this.recordId})
								.then((data) => {
								if(data == 'success'){
										this.showToast('Success','Template Updated Successfully', 'success');
								} else if (data == 'error_24_hour_limit') {
										this.showToast('Error','Template can only be edited once in 24 hours','error');
								} else {
										this.showToast('Error', 'Failed to Edit template', 'error');
								}

								this.dispatchEvent(new CloseActionScreenEvent());

						}).catch(() => {
								this.showToast('Error', 'Failed to Edit template', 'error');
						});
						this.isLoading = false;
				} 
				else {
					console.log('The template data is---->',JSON.stringify(this.templateData));
						save({ templateDataStr })
								.then(() => {
								this.showToast('Success', 'Template Saved Successfully', 'success');
								this.isLoading = false;
								this.templateData = {
										header: 'none',
										channel: null,
										objectName: null,
										bodyText: '',
										footerText: '',
										headerText: '',
										buttons: [],
										headerMedia: {}
								};
						})
								.catch(() => {
								this.showToast('Error', 'Failed to save template', 'error');
								this.isLoading = false;
						});

				}
		}
		showToast(title, message, variant) {
				const event = new ShowToastEvent({ title, message, variant });
				this.dispatchEvent(event);
		}
		handleChangeButtonText(event) {
				this.templateData.buttons[event.detail.indx] = event.detail.buttonData;
		}
}