import {LightningElement,track,api,wire} from 'lwc';
import WhatsAppIcon from '@salesforce/resourceUrl/WhatsAppIcon';
import SmsIcon from '@salesforce/resourceUrl/SmsIcon';
import SentTickIcon from '@salesforce/resourceUrl/SentTickIcon';
import DeliveredTickIcon from '@salesforce/resourceUrl/DeliveredTickIcon';
import SeenTickIcon from '@salesforce/resourceUrl/SeenTickIcon';
import WhatsAppBackground from '@salesforce/resourceUrl/WhatsAppBackground';
import hasUserPermission from '@salesforce/apex/ChatComponentController.hasUserPermission';
import listAllMessages from '@salesforce/apex/ChatComponentController.listAllMessages';
import getRecordDetails from '@salesforce/apex/ChatComponentController.getRecordDetails';
import getPhoneFieldName from '@salesforce/apex/ChatComponentController.getPhoneFieldName';
import savePhoneFieldName from '@salesforce/apex/ChatComponentController.savePhoneFieldName';
import getTemplates from '@salesforce/apex/ChatComponentController.getTemplates';
import sendSMS from '@salesforce/apex/ChatComponentController.sendSMS';
import scheduleSMS from '@salesforce/apex/ChatComponentController.scheduleSMS';
import createMessageRecord from '@salesforce/apex/ChatComponentController.createMessageRecord';
import createScheduleRecord from '@salesforce/apex/ChatComponentController.createScheduleRecord';
import createWhatsAppScheduleRecord from '@salesforce/apex/ChatComponentController.createWhatsAppScheduleRecord';
import listWAMessages from '@salesforce/apex/ChatComponentController.listWAMessages';
import sendTextMessage from '@salesforce/apex/ChatComponentController.sendTextMessage';
import constructPayload from '@salesforce/apex/WhatsAppServices.constructPayload';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {subscribe,unsubscribe,onError} from 'lightning/empApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { label } from './constant';
const twilioErrorMessages = {
		'30111': 'Url is on a deny list',
		'57016': "'Topic' is empty",
		'30118': 'Private key is invalid',
		'21725': 'Brand can only be updated when in FAILED state',
		'30006': 'Landline or unreachable carrier',
		'30117': 'Certificate cannot be parsed',
		'30107': 'Domain private certificate has not been uploaded',
		'57013': "'Topic' is absent",
		'57020': 'Authorization failed',
		'30019': 'Content size exceeds carrier limit',
		'30043': 'International SMS via Domestic Gateway',
		'90009': 'The message SID already exists.',
		'92008': 'Unsupported Content Type',
		'90007': 'Invalid validity period value',
		'30124': 'MessagingServiceSID cannot be empty or null',
		'63016': 'Failed to send freeform message because you are outside the allowed window. If you are using WhatsApp please use a Message Template.',
		'21654': 'ContentSid Required',
		'30409': 'This message cannot be canceled',
		'63036': 'The specified phone number cannot be reached by RBM at this time.',
		'30119': 'Certificate and private key pair is invalid',
		'21606': 'The "From" phone number provided is not a valid message-capable Twilio phone number for this destination/account',
		'63031': "Channels message cannot have same 'From' and 'To'",
		'23004': 'Message Redaction Incompatible Configuration: Advanced Opt-Out',
		'11751': 'Media Message - Media exceeds messaging provider size limit',
		'30036': 'Validity Period Expired',
		'30121': 'Fallback URL is missing',
		'21611': 'This "From" number has exceeded the maximum number of queued messages',
		'30027': 'US A2P 10DLC - T-Mobile Daily Message Limit Reached',
		'63008': 'Could not execute the request because the channel module has been misconfigured. Please check the Channel configuration in Twilio',
		'23002': 'Message Redaction Incompatible Configuration: Short code "STOP" filtering',
		'30011': 'MMS not supported by the receiving phone number in this region',
		'30130': 'Messaging Service SID already belongs in another domain configuration.',
		'21627': 'Max Price must be a valid float',
		'23005': 'Phone Number Redaction Incompatible Configuration: Fallback to Long Code',
		'90014': 'Validity Period should be positive integer',
		'92005': 'ContentSid Required',
		'21408': 'Permission to send an SMS or MMS has not been enabled for the region indicated by the "To" number',
		'35125': 'Maximum limit reached in the account for scheduling messages',
		'21712': 'Phone Number or Short Code is associated with another Messaging Service.',
		'57006': "'EventType' is empty",
		'57007': "'EventType' is absent",
		'30108': 'Twilio account does not belong to an organization',
		'57009': "'EventType' is too long",
		'30022': 'US A2P 10DLC - Rate Limits Exceeded',
		'30100': 'Domain SID is invalid',
		'30002': 'Account suspended',
		'92007': 'The Content Variables Parameter is invalid',
		'21723': 'Campaign Verify token import already in progress',
		'30009': 'Missing inbound segment',
		'63028': 'Number of parameters provided does not match the expected number of parameters',
		'30116': 'Certificate or private key or both are missing',
		'63001': 'Channel could not authenticate the request. Please see Channel specific error message for more information',
		'90006': 'Invalid direction',
		'30122': 'Fallback URL is invalid',
		'57018': "'Event' value type must be Map",
		'57003': "'Secret id' is invalid for this Partner",
		'30031': 'Invalid MaxRate',
		'57004': "'Category' is empty",
		'21614': "'To' number is not a valid mobile number",
		'63023': 'Channel generic error',
		'30041': 'Message from an unregistered number sent to a United Kingdom number',
		'21709': 'Alpha Sender ID is Invalid or Not Authorized for this Messaging Service',
		'21658': 'Parameter exceeded character limit',
		'21722': 'Invalid Campaign Verify token',
		'63038': 'Account exceeded the daily messages limit',
		'57002': "'Secret id' is too long",
		'63020': 'Twilio encountered a Business Manager account error',
		'63035': 'This operation is blocked because the RCS agent has not launched the recipient has not accepted the invitation to become a tester or the RCS sender only works in certain regions.',
		'63011': 'Invalid Request: Twilio encountered an error while processing your request',
		'92004': 'Invalid language code',
		'30133': 'The certificate could not be uploaded.',
		'21720': 'A2P Use Case is Invalid',
		'57011': 'Unsupported Partner name',
		'21711': 'Phone Number Shortcode or AlphaSender is not associated to the specified Messaging Service.',
		'30400': 'Parameters are not valid',
		'21605': 'Maximum body length is 160 characters (old API endpoint)',
		'21612': 'Message cannot be sent with the current combination of "To" and/or "From" parameters',
		'57017': "'Topic' is too long",
		'21619': 'A Message Body Media URL or Content SID is required',
		'30007': 'Message filtered',
		'63006': 'Could not format given content for the channel. Please see Channel specific error message for more information',
		'63029': 'The receiver failed to download the template',
		'30040': 'Destination carrier requires Sender ID pre-registration',
		'57021': 'Token invalid',
		'35126': 'The ScheduleType value provided is not supported for this channel',
		'30038': 'OTP Message Body Filtered',
		'35111': 'SendAt timestamp is missing',
		'30103': 'Links not shortened due to application failure.',
		'30105': 'Shortened link not found and no fallback URL found',
		'21710': 'Phone Number Already Exists in Messaging Service',
		'30404': 'Not Found',
		'57005': "'Category' is too long",
		'30129': 'Certificate is self signed',
		'21730': 'System under maintenance. Please try again later.',
		'30127': 'MessagingServiceSID is invalid.',
		'21902': 'InvoiceTag length must be between 0 and 32',
		'30128': 'MessagingServiceSidsAction is invalid',
		'30037': 'Outbound Messaging Disabled',
		'30032': 'Toll-Free Number Has Not Been Verified',
		'21910': "Invalid 'From' and 'To' pair. 'From' and 'To' should be of the same channel",
		'92009': 'The template associated with this SID has already been submitted for approval.',
		'57019': "'Authorization' header is missing or is invalid",
		'30125': 'Your phone number could not be registered with US A2P 10DLC',
		'63025': 'Media already exists',
		'30021': 'Internal Failure with messaging service orchestrator',
		'30485': "Message couldn't be delivered",
		'30123': 'Callback URL is missing',
		'63022': 'Invalid vname certificate',
		'30024': 'Numeric Sender ID Not Provisioned on Carrier',
		'30029': 'Invalid ContentRetention',
		'63009': 'Channel provider returned an internal service error (HTTP 5xx). Please see Channel specific error message for more information',
		'30114': 'Specified date is not available yet',
		'30003': 'Unreachable destination handset',
		'63003': 'Channel could not find To address',
		'30131': "Domain's certificate will expire soon",
		'35117': 'Scheduling does not support this timestamp',
		'21655': 'The ContentSid is Invalid',
		'30034': 'US A2P 10DLC - Message from an Unregistered Number',
		'63007': "Twilio could not find a Channel with the specified 'From' address",
		'30104': 'Shortened link not found. Click redirected to fallback Url',
		'30020': 'Internal Failure with Message Scheduling',
		'30450': 'Message delivery blocked',
		'30010': 'Message price exceeds max price',
		'21610': 'Attempt to send to unsubscribed recipient',
		'90001': 'Message SID is invalid',
		'21717': 'Brand Registration SID for US A2P Campaign Use Case is Not Registered or Not Valid',
		'57001': "'Secret id' is empty",
		'30454': 'Account exceeded the messages limit',
		'92002': 'The "variables" parameter exceeds the allowed limit',
		'90031': 'Broadcast Recipients list is empty [deprecated]',
		'63019': 'Media failed to download',
		'30026': 'US A2P 10DLC - 70% T-Mobile Daily Message Limit Consumed',
		'30115': 'Date format is incorrect',
		'35118': 'MessagingServiceSid is required to schedule a message'
};
export default class ChatComponent extends LightningElement {
		@track contactName;
		@track messages;
		@track errordetails;
		@track selectedOption = 'SMS';
		@track smsOption = true;
		@track whatsAppOption;
		@track selectedTemplateId;
		@track selectedTemplateBody = '';
		@track messageText;
		@api recordId;
		@api phoneNumber;
		@api objectApiName;
		@track phoneFieldOptions = [];
		@track selectedPhoneField;
		@track showFieldSelectionModal = false;
		isSpinner = false;
		@track showDropdown = false;
		whatsappIconUrl = WhatsAppIcon;
		smsIconUrl = SmsIcon;
		sentIconURL = SentTickIcon;
		deliveredIconUrl = DeliveredTickIcon; 
		seenIconUrl = SeenTickIcon;
		whatsAppBgURL = WhatsAppBackground;
		label = label;
		eventName = '/event/connectsocial__WhatsApp_Event__e' 
		subscription;
		@track showTemplateModal = false;
		@track showSchedulePopup = false;
		@track showMediaUrlModal = false;
		@track showReengagementPopup = false;
		@track HeadermediaUrl = '';
		@track Templates = [];
		@track filteredTemplates;
		@track selectedDate;
		@track selectedTime;
		phoneFieldName;
		isDocument = false;
		isEnterKeyPressed = false;
		@track fileName = '';
		@track groupedMessages = [];
		isPermissionError = false;

		get dropdownClass() {
				return this.showDropdown ? 'dropdown-content show' : 'dropdown-content hide';
		}
		get dropdownIcon() {
				return this.showDropdown ? 'utility:up' : 'utility:down';
		}
		get backgroundImageStyle() {
				return `background: linear-gradient(rgba(255, 255, 255, 0.5), rgba(255, 255, 255, 0.5)), url(${this.whatsAppBgURL});`;
		}

		@wire(hasUserPermission)
		wiredSettings(result) {
				if (result.error) {
						this.error = result.error.body.message;
						if(this.error == 'You do not have the required permissions to access this feature.' || this.error == 'You do not have access to the Apex class named \'ChatComponentController\'.'){
								this.isPermissionError = true;
						}
				}
		}

		toggleDropdown(event) {
				event.preventDefault();
				event.stopPropagation();
				this.showDropdown = !this.showDropdown;
				if (this.showDropdown) {
						this.selectedTime = null;
						this.showSchedulePopup = false;
						window.addEventListener('click', this.handleClickOutside.bind(this));
				} else {
						window.removeEventListener('click', this.handleClickOutside.bind(this));
				}
		}
		handleOptionSelection(event) {
				this.selectedOption = event.target.textContent;
				if (this.selectedOption == 'SMS') {
						this.smsOption = true;
						this.whatsAppOption = false;
						this.showReengagementPopup = false;
				}
				if (this.selectedOption == 'WhatsApp') {
						this.whatsAppOption = true;
						this.smsOption = false;
						this.checkReengagementMessage();
				} 
				this.dispatchEvent(new CustomEvent('optionselected', {
						detail: this.selectedOption
				}));
				this.showDropdown = false;
		}
		connectedCallback() {
				if(!this.isPermissionError){

						this.initializeComponent();
						this.handleErrorRegister();
						this.handleSubscribe();
						this.setDefaultDate();
				}
		}
		setDefaultDate() {
				const today = new Date();
				const year = today.getFullYear();
				const month = String(today.getMonth() + 1).padStart(2, '0'); 
				const day = String(today.getDate()).padStart(2, '0');
				this.selectedDate = `${year}-${month}-${day}`;
		}

		renderedCallback(){
				this.scrollToBottom();

		}
		disconnectedCallback() {
				this.handleUnSubscribe();
		}
		handleUnSubscribe() {
				if (this.subscription) {
						unsubscribe(this.subscription);
						this.subscription = null;
				}
		}
		handleSubscribe() {
				subscribe(this.eventName, -1, this.handleSubscribeResponse.bind(this)).then((response) => {
						this.subscription = response;
						console.log('The response is--->',response);
				});
		}
		handleSubscribeResponse() {
				this.loadMessages();
		}
		handleErrorRegister() {
				onError((error) => {
						console.error('Received error from server: ', JSON.stringify(error));
				});
		}
		@wire(getObjectInfo, { objectApiName: '$objectApiName' })
		objectInfo;
		initializeComponent() {
				getPhoneFieldName({ objectName: this.objectApiName })
						.then(phoneFieldName => {
						this.phoneFieldName = phoneFieldName;
						if (this.phoneFieldName) {
								this.retrieveRecordDetails();
						} else {
								this.populatePhoneFieldOptions();
								this.showFieldSelectionModal = true;
						}
				})
						.catch(error => {
						console.error('Error initializing component:', error);
				});
		}
		retrieveRecordDetails() {
				getRecordDetails({
						objectName: this.objectApiName,
						recordId: this.recordId,
						phoneField: this.phoneFieldName
				})
						.then(result => {
						if (result) {
								this.contactName = result.Name;
								this.phoneNumber = result.Phone;
								this.loadMessages();
						} else {
								console.error('Record details not found.');
						}
				})
						.catch(error => {
						console.error('Error fetching record details:', error);
				});
		}
		populatePhoneFieldOptions() {
				if (this.objectInfo.data) {
						const fields = this.objectInfo.data.fields;
						this.phoneFieldOptions = Object.keys(fields)
								.filter(fieldName => fields[fieldName].dataType === 'Phone')
								.map(fieldName => ({
								label: fields[fieldName].label,
								value: fieldName
						}));
				} else {
						console.error('Object info data not available.');
				}
		}
		handleFieldSelection(event) {
				this.selectedPhoneField = event.detail.value;
		}
		saveSelectedField() {
				savePhoneFieldName({
						objectName: this.objectApiName,
						phoneFieldName: this.selectedPhoneField
				})
						.then(() => {
						this.showFieldSelectionModal = false;
						this.retrieveRecordDetails(this.selectedPhoneField);
				})
						.catch(error => {
						console.error('Error saving phone field name:', error);
				});
		}
		loadMessages() {
				const smsPromise = listAllMessages({
						phoneNumber: '+' + this.phoneNumber
				});
				const whatsappPromise = listWAMessages({
						customerPhone: this.phoneNumber
				});
				Promise.all([smsPromise, whatsappPromise])
						.then(([smsResult, whatsappResult]) => {

						const formattedSMSMessages = this.formatMessages(smsResult);
						const formattedWhatsAppMessages = this.formatWhatsAppMessages(whatsappResult);
						this.messages = [...formattedSMSMessages, ...formattedWhatsAppMessages].sort((a, b) => {
								return new Date(a.CreatedDate) - new Date(b.CreatedDate);
						});

						this.groupMessagesByDate();
						this.checkReengagementMessage();

						this.scrollToBottom();
				})
						.catch(error => {
						console.error('Error fetching messages:', error);
						this.errordetails = error;
				});
		}
		checkReengagementMessage() {
				const now = new Date();
				const lastWhatsAppMessage = this.messages.filter(message => message.Incoming && message.isWhatsApp).pop();

				if (lastWhatsAppMessage && this.selectedOption === 'WhatsApp') {
						const lastMessageDate = new Date(lastWhatsAppMessage.CreatedDate);
						const diffInHours = (now - lastMessageDate) / (1000 * 60 * 60);

						if (diffInHours > 24) {
								this.showReengagementPopup = true;
						} else {
								this.showReengagementPopup = false;
						}
				} else {
						this.showReengagementPopup = false;
				}
		}

		groupMessagesByDate() {
				const grouped = this.messages.reduce((acc, message) => {
						const messageDate = new Date(message.CreatedDate);
						let dateKey;	
						const today = new Date();
						const yesterday = new Date(today);
						yesterday.setDate(today.getDate() - 1);

						if (messageDate.toDateString() === today.toDateString()) {
								dateKey = 'Today';
						} else if (messageDate.toDateString() === yesterday.toDateString()) {
								dateKey = 'Yesterday';
						} else {
								dateKey = messageDate.toLocaleDateString('en-GB', {
										weekday: 'short',
										day: '2-digit',
										month: 'short',
										year: 'numeric'
								});
						}
						if (!acc[dateKey]) {
								acc[dateKey] = [];
						}
						acc[dateKey].push(message);
						return acc;
				}, {});

				this.groupedMessages = Object.keys(grouped).map(date => {
						return {
								date: date,
								messages: grouped[date]
						};
				});
		}

		formatMessages(messages) {
				return messages.map(message => {
						const formattedScheduledTime = this.formatScheduledTime(message.connectsocial__Scheduled_Date_Time__c);
						return {
								...message,
								Outgoing: message.connectsocial__Type__c == 'Outbound' ? true : false,
								Incoming: message.connectsocial__Type__c === 'Inbound' && message.connectsocial__Delivery_Status__c === 'Received' ? true : false,
								Scheduled: message.connectsocial__Type__c == 'Outbound' && message.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
								sent: message.connectsocial__Delivery_Status__c == 'Sent'  ? true : false,
								delivered: message.connectsocial__Delivery_Status__c == 'Delivered'  ? true : false,
								read: message.connectsocial__Delivery_Status__c == 'Read'  ? true : false,
								isSMS: message.connectsocial__Channel__c == 'SMS' ? true : false,
								isWhatsApp: message.connectsocial__Channel__c == 'WhatsApp' ? true : false,
								formattedTime: this.formatTime(message.CreatedDate),
								formattedScheduledTime: formattedScheduledTime

						};

				});
		}
		get formattedScheduledTime() {
				return this.messages.map(message => this.formatScheduledTime(message.scheduledTime));
		}
		get formattedTime() {
				return this.messages.map(message => this.formatTime(message.dateTime));
		}
		formatScheduledTime(scheduledTime) {
				if (!scheduledTime) return '';
				const scheduledDateandTime = new Date(scheduledTime);
				const options = {
						weekday: 'long',
						month: 'short',
						day: '2-digit',
						hour: '2-digit',
						minute: '2-digit',
						hour12: true
				};
				const formattedScheduledDateTime = new Intl.DateTimeFormat('en-US', options).format(scheduledDateandTime);
				return `${formattedScheduledDateTime}`;
		}
		formatTime(dateTimeString) {
				if (!dateTimeString) return '';
				const date = new Date(dateTimeString);
				if (isNaN(date.getTime())) return '';
				const hours = date.getHours().toString().padStart(2, '0');
				const minutes = date.getMinutes().toString().padStart(2, '0');
				const time = `${hours}:${minutes}`;
				return time;
		}

		formatWhatsAppMessages(messages) {
				return messages.map(message => {
						const WAScheduledTime = message.connectsocial__Delivery_Status__c === 'Scheduled' ? this.formatScheduledTime(message.connectsocial__Scheduled_Date_Time__c) : '';
						const formattedMessage = {
								...message,
								Outgoing: message.connectsocial__Type__c ==='Outbound' ? true : false,
								Incoming: message.connectsocial__Type__c === 'Inbound' && message.connectsocial__Delivery_Status__c === 'Received' ? true : false,
								Scheduled: message.connectsocial__Type__c === 'Outbound' && message.connectsocial__Delivery_Status__c === 'Scheduled' ? true : false,
								sent: message.connectsocial__Delivery_Status__c == 'Sent'  ? true : false,
								delivered: message.connectsocial__Delivery_Status__c == 'Delivered'  ? true : false,
								read: message.connectsocial__Delivery_Status__c == 'Read'  ? true : false,
								isSMS: message.connectsocial__Channel__c === 'SMS' ? true : false,
								isWhatsApp: message.connectsocial__Channel__c === 'WhatsApp' ? true : false,
								formattedTime: this.formatTime(message.CreatedDate),
								WAScheduledTime: WAScheduledTime
						};
						return formattedMessage;
				});
		}
		handleMessageInputChange(event) {
				event.preventDefault();
				this.messageText = event.target.value || '';
				if(this.messageText == ''){
					this.selectedTemplateId = null;
				}
				this.isEnterKeyPressed = false;
		}
		handleFileNameChange(event){
				event.preventDefault();
				this.fileName = event.target.value;
		}
		@wire(getTemplates,{objectApiName: '$objectApiName',templateType:'$selectedOption'}) 
		wiredTemplates({error, data}) {
				if (data) {
						this.Templates = data;
						this.filteredTemplates = data;
				} else if (error) {
						this.error = error;
				}
		}
		showTemplates() {
				this.showTemplateModal = true;
				this.filteredTemplates = this.Templates;
		}
		closeModal() {
				this.showTemplateModal = false;
		}
		handleSearch(event) {
				const searchKeyword = event.target.value.toLowerCase();
				this.filteredTemplates = this.Templates.filter(template =>
																											 template.connectsocial__Template_Name__c.toLowerCase().includes(searchKeyword)
																											);
		}
		handleRowClick(event) {
				const templateId = event.currentTarget.dataset.id;
				const template = this.Templates.find(t => t.Id === templateId);
				const templateBody = template ? template.connectsocial__Body__c : '';
				const selectedTemplate = this.Templates.find(template => template.Id === templateId);
				this.selectedTemplateId = templateId;
				if (selectedTemplate.connectsocial__Header__c === 'Document' || selectedTemplate.connectsocial__Header__c === 'Image' || selectedTemplate.connectsocial__Header__c === 'Video') {
						this.showMediaUrlModal = true;
						if(selectedTemplate.connectsocial__Header__c === 'Document'){
								this.isDocument = true;
						}
				} 
				this.messageText = templateBody;
				if(selectedTemplate.connectsocial__Header__c === 'Document' || selectedTemplate.connectsocial__Header__c === 'Image' || selectedTemplate.connectsocial__Header__c === 'Video'){
						this.showTemplateModal = false;
				}
				else{
						this.showTemplateModal = false;
				}
		}
		handleMediaUrlChange(event) {
				this.HeadermediaUrl = event.target.value;
		}
		handleSaveMediaUrl() {
				this.showMediaUrlModal = false;
				this.showTemplateModal = false;
		}
		closeMediaUrlModal() {
				this.showMediaUrlModal = false;
		}
		handleSendTemplate(){
				this.showTemplateModal = true;
		}
		showSchedule() {
				event.preventDefault();
				event.stopPropagation();
				this.showSchedulePopup = !this.showSchedulePopup;
				if (this.showSchedulePopup) {
						window.addEventListener('click', this.handleClickOutside.bind(this));
						//this.selectedDate = null;
						this.setDefaultDate();
						this.selectedTime = null;
						this.errorMessage = '';
				} else {
						window.removeEventListener('click', this.handleClickOutside.bind(this));
				}
		}
		handleClickOutside(event) {
				const schedulePopup = this.template.querySelector('.scheduling-popup');
				if (schedulePopup && !schedulePopup.contains(event.target)) {
						this.showSchedulePopup = false;
						this.errorMessage = '';
						this.selectedDate = null;
						this.selectedTime = null;
						window.removeEventListener('click', this.handleClickOutside.bind(this));
				}
				const dropdown = this.template.querySelector('.dropdown');
				if (dropdown && !dropdown.contains(event.target)) {
						this.showDropdown = false;
						window.removeEventListener('click', this.handleClickOutside.bind(this));
				}
		}
		stopPropagation(event) {
				event.stopPropagation();
		}
		get todaysDate() {
				const today = new Date();
				const year = today.getFullYear();
				const month = String(today.getMonth() + 1).padStart(2, '0'); 
				const day = String(today.getDate()).padStart(2, '0');
				return `${year}-${month}-${day}`;
		}
		handleDateChange(event) {
				this.selectedDate = event.target.value;
		}
		handleTimeChange(event) {
				const selectedTime = event.target.value;
				const selectedDate = this.selectedDate;
				if (this.selectedOption === 'SMS' && !this.isTimeValid(selectedDate, selectedTime)) {
						this.errorMessage = 'Selected time must be at least 15 minutes from now.';
						this.selectedTime = ''; 
				} else {
						this.selectedTime = selectedTime;
						this.errorMessage = ''; 
				}
		}
		isTimeValid(selectedDate, selectedTime) {
			const currentTime = new Date();
			const selectedDateTime = new Date(selectedDate); 
			const [hours, minutes] = selectedTime.split(':').map(Number);
			selectedDateTime.setHours(hours, minutes, 0, 0);
			const isSameDay = selectedDateTime.toDateString() === currentTime.toDateString();
			const timeDifference = (selectedDateTime - currentTime) / (1000 * 60);
			return isSameDay ? timeDifference >= 15 : true;
		}


		handleContinue() {
				if (!this.selectedDate || !this.selectedTime) {
						return;
				}
				if(this.selectedOption == 'SMS'){
						this.scheduleMessage();
				}
				else if(this.selectedOption == 'WhatsApp'){
						this.scheduleWhatsAppMessage();
				}
		}
		scheduleMessage() {
				if (!this.phoneNumber || !this.messageText && this.selectedOption == 'SMS') {
						return;
				}
				const scheduledDateTime = new Date(`${this.selectedDate}T${this.selectedTime}Z`);
				scheduledDateTime.setHours(scheduledDateTime.getHours() - 5);
				scheduledDateTime.setMinutes(scheduledDateTime.getMinutes() - 30);
				const adjustedUtcDateTime = scheduledDateTime.toISOString();

				const params = {
						phoneNumber: this.phoneNumber,
						smsBody: this.messageText,
						status: 'sent',
						scheduledTime: adjustedUtcDateTime
				};
				createScheduleRecord({ smsparams: params })
						.then(() => {
						scheduleSMS({
								recordId:this.recordId,
								phoneNumber: '+' + this.phoneNumber,
								smsBody: this.messageText,
								scheduledTime: adjustedUtcDateTime
						})
								.then(result => {
								const updatedResult = Object.assign({
										Outgoing: result.connectsocial__Type__c == 'Outbound' ? true : false,
										Incoming: result.connectsocial__Type__c === 'Inbound' && result.connectsocial__Delivery_Status__c == 'Received' ? true : false,
										Scheduled: result.connectsocial__Type__c == 'Outbound' && result.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
										isSMS: result.connectsocial__Channel__c == 'SMS' ? true : false,
										isWhatsApp: result.connectsocial__Channel__c == 'WhatsApp' ? true : false
								}, result);
								const newMessage = {
										...updatedResult
								};
								newMessage.formattedScheduledTime = this.formatScheduledTime(newMessage.connectsocial__Scheduled_Date_Time__c);
								newMessage.formattedTime = this.formatTime(newMessage.CreatedDate);
								this.messages = [...this.messages, newMessage];
								this.groupMessagesByDate();
								refreshApex(this.messages);
						})
								.catch(error => {

								console.error('Error scheduling message:', error);

						})
								.finally(() => {
								this.isSpinner = false;
								this.scrollToBottom();
								this.messageText = '';
								this.showSchedulePopup = false;
								this.selectedDate = null;
								this.selectedTime = null;
						});
				})
						.catch(error => {
						console.error('Error creating message record:', error);
				});

		}

		scheduleWhatsAppMessage(){
				if (!this.phoneNumber || !this.messageText) {
						return;
				}
				const scheduledDateTime = new Date(`${this.selectedDate}T${this.selectedTime}`);
				const formattedScheduledDateTime = scheduledDateTime.toISOString();

				const params = {
						phoneNumber: this.phoneNumber,
						messageBody: this.messageText,
						status: 'Scheduled',
						scheduledTime: formattedScheduledDateTime
				};
				createWhatsAppScheduleRecord({ whatsappparams: params })
						.then(result => {
						const updatedResult = Object.assign({
								Outgoing: result.connectsocial__Type__c == 'Outbound' ? true : false,
								Incoming: result.connectsocial__Type__c === 'Inbound' && result.connectsocial__Delivery_Status__c == 'Received' ? true : false,
								Scheduled: result.connectsocial__Type__c == 'Outbound' && result.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
								isSMS: result.connectsocial__Channel__c == 'SMS' ? true : false,
								isWhatsApp: result.connectsocial__Channel__c == 'WhatsApp' ? true : false
						}, result);
						const newMessage = {
								...updatedResult
						};
						newMessage.WAScheduledTime = this.formatScheduledTime(newMessage.connectsocial__Scheduled_Date_Time__c);
						newMessage.formattedTime = this.formatTime(newMessage.CreatedDate);
						this.messages = [...this.messages, newMessage];
						this.groupMessagesByDate();
				})
						.catch(error => {
						console.error('Error scheduling message:', error);
				})
						.finally(() => {
						this.isSpinner = false;
						this.scrollToBottom();
						this.messageText = '';
						this.showSchedulePopup = false;
						this.selectedDate = null;
						this.selectedTime = null;
				});
		}
		handleKeyPress(event) {		
				if (event.key === 'Enter' && event.shiftKey === false) {
						this.isEnterKeyPressed = false;
						this.handleSendMessage();
				} else  {
						this.isEnterKeyPressed = true;
						event.stopPropagation(); 
				}
		}
		get sendButtonClass() {
				if (this.showSchedulePopup || !(this.messageText && this.messageText.trim())) {
						return 'send-icon disabled-icon';
				}
				return 'send-icon';
		}
		handleSendButtonClick(event) {
				event.preventDefault();
				if (!this.isSendButtonDisabled) {
						this.handleSendMessage();
				}
		}
		get isSendButtonDisabled() {
				return !this.messageText.trim();
		}
		handleSendMessage() {
				if(!this.isEnterKeyPressed) {
						this.isEnterKeyPressed = true;
						if (this.selectedOption === 'SMS') {
								this.sendSMSMessage();
						} else if (this.selectedOption === 'WhatsApp') {
								this.sendWhatsAppMessage();
						} else {
								console.error('Invalid messaging option.');
						}
				}
		}

		sendSMSMessage() {
				let msgText = this.messageText.replaceAll(' ','');
				msgText = msgText.replace(/\\\\/g, '\\');
				if(msgText){
						if (!this.phoneNumber) {
								console.error('Phone number not found for the record or the selected Option is not SMS.');
								return;
						}
						createMessageRecord({
								phoneNumber: this.phoneNumber,
								smsBody: this.messageText,
								status: 'sent'
						})
								.then(() => {
								sendSMS({
										recordId:this.recordId,
										phoneNumber: '+' + this.phoneNumber,
										smsBody: this.messageText
								})
										.then(result => {
										const updatedResult = Object.assign({
												Outgoing: result.connectsocial__Type__c == 'Outbound' ? true : false,
												Incoming: result.connectsocial__Type__c == 'Inbound' && result.connectsocial__Delivery_Status__c == 'Received' ? true : false,
												Scheduled: result.connectsocial__Type__c == 'Outbound' && result.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
												isSMS: result.connectsocial__Channel__c == 'SMS' ? true : false,
												isWhatsApp: result.connectsocial__Channel__c == 'WhatsApp' ? true : false,
										}, result);
										const newMessage = {
												...updatedResult
										};
										newMessage.formattedTime = this.formatTime(newMessage.CreatedDate);
										this.messages = [...this.messages, newMessage];
										this.groupMessagesByDate();
								})
										.catch(error => {
										console.error('Error sending message:', JSON.stringify(error));
										let errorMessage = 'Unknown error occurred';

										if (error.body) {
												errorMessage = error.body.message.split(' Code:')[0] || errorMessage;
										} else if (error.message && error.message.includes('Error :')) {
												errorMessage = error.message.replace('Error : ', '').split(' Code:')[0];
										}

										this.showErrorNotification('Error Sending Message', errorMessage);
								})
										.finally(() => {
										this.isEnterKeyPressed = false;
										this.isSpinner = false;
										this.scrollToBottom();
										this.messageText = '';
										this.setUpChatMessage();
								});
						})
								.catch(error => {
								console.error('Error creating message record:', error);
						});
				}
				else{
						this.isEnterKeyPressed = false;
				}
		}
		getTwilioErrorMessage(errorCode) {
				return twilioErrorMessages[errorCode] || 'Unknown error occurred';
		}
		showErrorNotification(title, message) {
				const event = new ShowToastEvent({
						title: title,
						message: message,
						variant: 'error',
				});
				this.dispatchEvent(event);
		}
		setUpChatMessage() {
				let chatInput = this.template.querySelector(".chat-input");
				if (chatInput) {
						chatInput.addEventListener("keydown", (event) => {
								if (event.key === "Enter") {
										this.handleSendMessage();
								}
						});
				}
		}
		sendWhatsAppMessage() {
				let allValid = this.handleValidate();
				if (allValid && this.selectedOption == 'WhatsApp') {
						if (!this.isSpinner && this.selectedTemplateId) {
								this.isEnterKeyPressed = false;
								constructPayload({ recordId:this.recordId, templateId: this.selectedTemplateId, phoneNumber: this.phoneNumber, headerMediaURL: this.HeadermediaUrl,fileName:this.fileName})
										.then(result => {
										const updatedResult = Object.assign({
												Outgoing: result.connectsocial__Type__c == 'Outbound' ? true : false,
												Incoming: result.connectsocial__Type__c === 'Inbound' && result.connectsocial__Delivery_Status__c == 'Received' ? true : false,
												Scheduled: result.connectsocial__Type__c == 'Outbound' && result.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
												sent: result.connectsocial__Delivery_Status__c == 'Sent'  ? true : false,
												delivered: result.connectsocial__Delivery_Status__c == 'Delivered'  ? true : false,
												read: result.connectsocial__Delivery_Status__c == 'Read'  ? true : false,
												isSMS: result.connectsocial__Channel__c == 'SMS' ? true : false,
												isWhatsApp: result.connectsocial__Channel__c == 'WhatsApp' ? true : false
										}, result);
										const newMessage = {
												...updatedResult
										};
										newMessage.formattedTime = this.formatTime(newMessage.CreatedDate);
										this.messages = [...this.messages, newMessage];
										this.groupMessagesByDate();
										this.scrollToBottom();
								})
										.catch(error => {
										console.error('Error sending template message:', error);
								})
										.finally(() => {
										this.isSpinner = false;
										this.messageText = '';
										this.selectedTemplateId = null;
										this.showReengagementPopup = false;
								});
						} else if (!this.isSpinner && !this.selectedTemplateId) {
								sendTextMessage({
										messageContent: this.messageText,
										toPhone: this.phoneNumber
								})
										.then(result => {
										const updatedResult = Object.assign({
												Outgoing: result.connectsocial__Type__c == 'Outbound' ? true : false,
												Incoming: result.connectsocial__Type__c === 'Inbound' && result.connectsocial__Delivery_Status__c == 'Received' ? true : false,
												Scheduled: result.connectsocial__Type__c == 'Outbound' && result.connectsocial__Delivery_Status__c == 'Scheduled' ? true : false,
												sent: result.connectsocial__Delivery_Status__c == 'Sent'  ? true : false,
												delivered: result.connectsocial__Delivery_Status__c == 'Delivered'  ? true : false,
												read: result.connectsocial__Delivery_Status__c == 'Read'  ? true : false,
												isSMS: result.connectsocial__Channel__c == 'SMS' ? true : false,
												isWhatsApp: result.connectsocial__Channel__c == 'WhatsApp' ? true : false
										}, result);
										const newMessage = {
												...updatedResult
										};
										newMessage.formattedTime = this.formatTime(newMessage.CreatedDate);
										this.messages = [...this.messages, newMessage];
										this.groupMessagesByDate();
										this.scrollToBottom();
								})
										.catch((errors) => {
										this.errorDetails = errors;
										this.showMessages = false;
								})
										.finally(() => {
										this.scrollToBottom();
										this.handleSubscribe();
										this.messageText = '';
								});
						}
				}
		}
		scrollToBottom() {
				let scroll = this.template.querySelector('.scrollable-container');
				if (scroll) {
						scroll.scrollTop = scroll.scrollHeight;
				}
		}
		handleValidate() {
				const allValid = [
						...this.template.querySelectorAll('lightning-input'),
				].reduce((validSoFar, inputCmp) => {
						inputCmp.reportValidity();
						return validSoFar && inputCmp.checkValidity();
				}, true);
				return allValid;
		}

}