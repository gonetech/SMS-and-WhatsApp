/**
 * @description Represents the structure of a WhatsApp message, including nested classes for detailed message components.
 */
public class WhatsAppMessage {
    /**
     * @description An array of Entry objects representing individual entries in the WhatsApp message.
     */
     public Entry[] entry;
    /**
     * @description Represents an entry in the WhatsApp message, containing an ID and an array of changes.
     */
    public class Entry {
        public String id;	
        public Changes[] changes;
    }
    /**
     * @description Represents changes in the WhatsApp message, containing a value object and a field string.
     */
    public class Changes {
        public Value value;
        public String field;	
    }
	/**
     * @description Represents the value of changes in the WhatsApp message, containing metadata, contacts, and messages.
     */
    public class Value {
        public String messagingproduct;
        public metadata metadata;
        public Contacts[] contacts;
        public Messages[] messages;
    }
	 /**
     * @description Represents metadata in the WhatsApp message, containing display phone number and phone number ID.
     */
    public class Metadata {	
        public String displayphonenumber;
        public String phonenumberid;	
    }
	/**
     * @description Represents a contact in the WhatsApp message, containing profile and WhatsApp ID.
     */
    public class Contacts {
        public Profile profile;
        public String waid;	
    }
	/**
     * @description Represents a profile in the WhatsApp contact, containing name and type.
     */
    public class Profile {
        public String name;	
        public String type;
    }
	/**
     * @description Represents a message in the WhatsApp message, containing context, various message types, and other details.
     */
    public class Messages {
        public Context context;
        public String fromx;	
        public String id;	
        public String timestamp;	
        public Text text;
        public String typex;	
        public Reaction reaction;
        public Image image;
        public Image video;
        public Document document;
        public Location location;
        public Button button;
    }
	 /**
     * @description Represents the context of the WhatsApp message, containing sender information.
     */
    public class Context {
        public String fromx;	
        public String id;	
    }
	 /**
     * @description Represents the text of the WhatsApp message, containing the message body.
     */
    public class Text {
        public String body;	
    }
	/**
     * @description Represents a reaction in the WhatsApp message, containing an emoji and message ID.
     */
    public class Reaction{
        public String emoji;
        public String messageid;
    }
	/**
     * @description Represents an image in the WhatsApp message, containing MIME type, ID, and SHA256 hash.
     */
    public class Image{
        public String mimetype;
        public String id;
        public String sha256;
    }
	/**
     * @description Represents a document in the WhatsApp message, containing MIME type, ID, and SHA256 hash.
     */
    public class Document {
        public String mimetype;
        public String id;
        public String sha256;     
    }
	/**
     * @description Represents a button in the WhatsApp message, containing text and payload.
     */
    public class Button {
        public String text;
        public String payload;
    }
	/**
     * @description Represents a location in the WhatsApp message, containing address, latitude, longitude, name, and URL.
     */
    public class Location {
        public String address;
        public String latitude;
        public String longitude;
        public String name;
        public String url;
        
    }

}