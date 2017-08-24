//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  SecureBrowser.js
//  Secure Browser
//
//  Created by Han Yu on 05/17/17.
//
MSB = function () {

    var AIRMobile = {

        ttsCallbackId: null,
        recorderCallbackId: null,
        audioCallbackId: null,

        eventsCallbackId: new Map(),

	    /**
	     *  @ignore @private Registered callbacks.
	     */
	    callbacks: {},

	    /** @namespace Represents the current status of the device. Users should treat
	     *  the properties of this object as read only. Additionally, some properties may
	     *  only apply to one type of software, iPhone OS devices, and Android devices, when
	     *  this occurs, it is indicated in the properties documentation. */
	    device: {

		    /** Status of the device. When true, the device has responded to
		     *  the initialization request and the fields have been set with
		     *  values reflecting it's state.
		     *  @type Boolean
		     */
		    isReady: false,

		    /** The AIRMobile version that the native application was built against.
		     *  A negative value indicates the field is uninitialized or unknown.
		     *  @type Number
		     */
		    apiVersion: -1.0,

		    /** The intial url that the application loads when started.
		     *  @type String
		     */
		    defaultURL: "Unknown",

		    /** Jailbroken/Rooted Status. When true, the native application has
		     *  detected that the device has been jailbroken or rooted. Note that
		     *  the application may not be able to detect this under all circumstances.
		     *  For instance, on iOS the device may check for the presence of a directory
		     *  typically found on jailbroken devices. The absence of this directory
		     *  does not mean the device is not jailbroken, only that we have not detected
		     *  that it is jailbroken.
		     *  @type boolean
		     */
		    rootAccess: false,

		    /** The device model. A String representing the model of the hardware.
		     *  eg. iPad, iPhone
		     *  @type String
		     */
		    model: "Unknown",

		    /** The device manufacturer. A string representing the device manufacturer.
		     *	eg. Apple, Samsung etc.
		     *	@type String
		     */
		    manufacturer: "Unknown",

		    /** The name of the operating system running on the device.
		     *  eg. iphone OS
		     *  @type String
		     */
		    operatingSystem: "Unknown",

		    /** The version of the operating system running on the device.
		     *  @type String
		     */
		    operatingSystemVersion: "Unknown",

		    /** The internet connectivity status of the device. <br>
		     *  Possible values include: <ul>
		     *  <li>'connected'</li>
		     *  <li>'disconnected'</li>
		     *  </ul>
		     *  @type String
		     */
		    connectivityStatus: "Unknown",

		    /** Status of Guided Access (iPhone OS ONLY). When true, guided access is
		     *  enabled on the device. Otherwise, guided access is disabled.
		     *  *Note: On android devices, this property will always be false, as android
		     *  devices do not have a guided access mode.
		     *  @type Boolean
		     */
		    guidedAccessEnabled: false,

		    /** Status of Text-To-Speech on the device. *Note this refers to the state native accessibility framework for the device.
		     *  On iOS, this corresponds to the "VoiceOver" accessibility option. On android this corresponds to the TalkBack accessibility
		     *  setting.
		     *  @type Boolean
		     */
		    textToSpeechEnabled: false,

		    /** Status of Text-To-Speech engine on the device. To receive notifications on status change
		     *  use EVENT_TTS_CHANGED. This property refers to the capability the application has of speaking
		     *  text passed via javascript. If the device is capable of handling these requests, its state will
		     *  be either 'idle' or 'playing', otherwise, a status of 'unavailable' will be reported.
		     *	Possible values include: <ul>
		     *	<li>'idle' - A TTS engine is available for use, and is not currently playing audio</li>
		     *	<li>'playing' - A TTS engine is available for use, and is currently playing audio</li>
		     *  <li>'unavailable' - A TTS engine is not available on the device. </li>
		     *	@type String
		     */
		    ttsEngineStatus: "unavailable",

		    /** A list of running processes on the device.
		     *  @type Array
		     */
		    runningProcesses: [],

		    /** A list of installed packages on the device (Android ONLY)
		     * @type Array
		     */
		    installedPackages: [],

		    /** The devices screen resolution.
		     * eg. "{width, height}"
		     */
		    screenResolution: "Unknown",

		    /** The devices current orientation.
		     *	Possible values include: <ul>
		     *  <li>'portrait'</li>
		     *  <li>'landscape'</li>
		     *	<li>'unknown'</li>
		     *  </ul>
		     *	@type String
		     */
		    orientation: "Unknown",

		    /** The status of orientation lock.
		     *	Possible values include: <ul>
		     *	<li>'portrait'</li>
		     *	<li>'landscape'</li>
		     *	<li>'none'</li>
		     *	</ul>
		     *	@type String
		     */
		    lockedOrientation: "none",

		    /** The keyboard that users device is configured to use.
		     *  This property is currently unique to android as the user can swap out
		     *  the keyboard. The included keyboard, which the user is required to switch
		     *  to currently has the package name: 'com.air.mobilebrowser/.softkeyboard.SoftKeyboard'
		     *  @type String
		     */
		    keyboard: "unknown",

		    /** The status of the devices microphone.
             @type Boolean */
		    micMuted: false,

		    /** The IP address of the device.
             @type String */
            ipAddress : "unknown",

            /** The MAC address of the device.
             @type String */
            macAddress : "unknown",
            
            /** The brand name of the Secure Browser.
             @type String */
            brand : "unknown",

            /** A Timestamp from when the app was launched.
             @type String */
            startTime : "unknown",

	        /** A list of voice packs supported by the browser.
             @type String */
            ttsVoices: "unknown",

	        /** tts pitch.
             @type integer */
            ttsPitch: 0,

	        /** tts rate.
             @type integer */
            ttsRate: 0,

	        /** tts volume.
             @type integer */
            ttsVolume: 0,


		    /** Check if the device can currently take screenshots. For iphone OS,
		     *  this returns true when guided access is disabled, false otherwise. On
		     *  android, this function always returns false, this is because the native application
		     *  blocks the standard mechanism for taking screenshots. Users should also inspect
		     *  the installed applications property for android devices to ensure that the user
		     *  does not have an application that directly accesses the screenbuffer installed.
		     *  @return {Boolean} true if it has been detected that the device can currently take a sceenshot by standard means.
		     */
		    screenShotsEnabled: function() {
			    var isIOS, isAndroid;

			    isIOS = this.operatingSystem.toLowerCase() == "iphone os";
			    isAndroid = !isIOS;

			    if (isIOS) {
				    return this.guidedAccessEnabled ? false : true;
			    } else if (isAndroid) {
				    return false;
			    }
			    return true;
		    },

		    /** Check if the device supports a given feature.
		     *  <br><br>*NOTE This does not indicate if the feature is enabled, only
		     *  that we expect the device to support it.
		     *  The result is based off of the operating system reported by the device,
		     *  eg. iphone OS supports guided access mode, Android does not.<br><br>
		     *
		     *  Valid feature values:<br>
		     *
		     *  <ul>
		     *  <li>'guided_access' - Guided Access Mode</li>
		     *  <li>'text_to_speech' - Text To Speech (Accessibility Detection)</li>
		     *  <li>'running_processes' - Running Processes</li>
		     *  <li>'installed_packages' - Installed Packages</li>
		     *  <li>'audio_recording' - Audio Recording</li>
		     *  <li>'mic_mute' - Mice Muting</li>
		     *  <li>'tts_engine' - Text To Speech (Speech Synthesis)</li>
		     *  <li>'exit' - Exit the app via javascript
		     *  </ul>
		     *  @param {String} feature the feature to check for compatibility.
		     *  @return {Boolean} true if the device supports the feature, false otherwise.
		     */
		    supportsFeature: function(_feature) {
			    var isIOS, isAndroid;

			    isIOS = this.operatingSystem.toLowerCase() == "iphone os";
			    isAndroid = this.operatingSystem.toLowerCase() == "android";

			    if (_feature == "guided_access") //Only ios
			    {
				    return isIOS;
			    } else if (_feature == "text_to_speech") //either
			    {
				    return isIOS || isAndroid;
			    } else if (_feature == "running_processes") //either
			    {
				    return isIOS || isAndroid;
			    } else if (_feature == "installed_packages") //android
			    {
				    return isAndroid;
			    } else if (_feature == "mic_mute") //android
			    {
				    return isAndroid;
			    } else if (_feature == "tts_engine") //either
			    {
				    return isAndroid || isIOS;
			    } else if (_feature == "exit") //android
			    {
				    return isAndroid;
			    }

			    return false;
		    },

		    /** Convenience function for printing the device info.
		     *  @returns {String} a string in the form
		     *  "Device: 'device_name', OS: 'os_name', Version: 'os_version', Jailbroken : 'yes_or_no', Resolution : {width, height}"gui
		     */
		    formattedDeviceInfo: function() {
			    var isiOS = this.operatingSystem.toLowerCase() == "iphone os";

			    return "Device: " + this.model + ", OS: " + this.operatingSystem + ", Version: " + this.operatingSystemVersion + (isiOS ? ", Jailbroken: " : ", Rooted: ") + (this.rootAccess ? "Yes" : "No") + ", Resolution: " + this.screenResolution;
		    }

	    },

	    initialize: function () {

	        var messgeToPost = { };
	        window.webkit.messageHandlers.initialize.postMessage(messgeToPost);
	    },

	    onDeviceReady: function (_parameters) {
	        var results = JSON.parse(_parameters, null);

	        this.device.isReady = true;
	        this.device.apiVersion = results.apiVersion != null ? results.apiVersion : -1.0;
	        this.device.model = results.model;
	        this.device.manufacturer = results.manufacturer;
	        this.device.operatingSystem = results.operatingSystem;
	        this.device.operatingSystemVersion = results.operatingSystemVersion;
	        this.device.runningProcesses = results.runningProcesses;
	        this.device.installedPackages = results.installedPackages;
	        this.device.rootAccess = results.rootAccess;
	        this.device.connectivityStatus = results.connectivity;
	        this.device.defaultURL = results.defaultURL;
	        this.device.textToSpeechEnabled = results.textToSpeech;
	        this.device.guidedAccessEnabled = results.guidedAccess;
	        this.device.screenResolution = results.screenResolution;
	        this.device.orientation = results.orientation;
	        this.device.lockedOrientation = results.lockedOrientation;
	        this.device.ttsEngineStatus = results.ttsEngineStatus;
	        this.device.keyboard = results.keyboard;
	        this.device.micMuted = results.muted;
	        this.device.ipAddress = results.ipAddress;
	        this.device.startTime = results.startTime;
            this.settings.appStartTime = results.startTime;
	        this.device.macAddress = results.macAddress;
            this.device.brand = results.brand;
	        this.device.ttsVoices = results.availableTTSLanguages;
	        if (results.ttsSettings != null) {
	            this.device.ttsPitch = results.ttsSettings.pitch;
	            this.device.ttsRate = results.ttsSettings.rate;
	            this.device.ttsVolume = results.ttsSettings.volume;
	        }
	    },

	    /** Dispatch an event using the document; with the given name.
	     *
	     *  @param eventName the name of the event to dispatch
	     *  @return true if the event was dispatched, false if not.
	     *  @private
	     */
	    dispatchEvent: function(_eventName) {
		    var result, event;

		    result = false;

		    if (_eventName && _eventName.length > 0) {
			    event = document.createEvent("Event");
			    event.initEvent(_eventName, true, true);
			    document.dispatchEvent(event);
			    result = true;
		    }

		    return result;
	    },

	    dispatchMessageEvent: function(_eventName, _message) {
		    var result, origin, event;

		    result = false;

		    if (_eventName && _eventName.length > 0) {
			    //CustomEvent would work better here
			    origin = window.location.protocol + "//" + window.location.host;
			    event = document.createEvent("MessageEvent");
			    event.initMessageEvent(_eventName, true, true, _message, origin, 12, window, null);
			    document.dispatchEvent(event);
			    result = true;
		    }

		    return result;
	    },

	    /** Executes the callback corresponding to the response object provided.
	     *
	     *  @param {Object} responseObject the parsed response object.
	     *  @config {String} identifier the original request identifier.
	     *  @return true if a callback was found, false if no callback was found.
	     *  @private
	     */
	    executeCallback: function(_responseObject, identifier, persistent) {
		    var callback, result = false;

		    if (identifier != null) callback = this.callbacks[identifier];

		    if (callback != null && typeof callback == 'function') {
		        if (persistent != true) {
		            delete this.callbacks[identifier];
		        }
			    callback(_responseObject);
			    result = true;
		    }

		    return result;
	    },

	    /** Utility function to generate a unique identifier. Users can call
	     *  this to generate an identifier for request methods.
	     *  @return {String} a unique string
	     */
	    UUID: function() {
		    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			    var r = Math.random() * 16 | 0,
				    v = c == 'x' ? r : (r & 0x3 | 0x8);
			    return v.toString(16);
		    });

	    },

	    /** Convenience function to add a listener to an event.
	     *  Supports W3C and IE event mechanisms.
	     *  @param {String} event the name of the event to listen for.
	     *  @param {Object} element the element that will fire the event.
	     *  @param {Function} function the function to call when the event fires.
	     */
	    listen: function (evnt, elem, func, disposeAfterFired) {
            if (disposeAfterFired === true) {
                var handler = func;
                func = function () {
                    // invoke the actual handler
                    var args = [].slice.call(arguments);
                    handler.apply(this, args);

                    // remove this handler
                    if (elem.removeEventListener) {
                        elem.removeEventListener(evnt, func);
                    }
                    else if (elem.detachEvent) {
                        elem.detachEvent('on' + evnt, func);
                    }
                };
            }

		    if (elem.addEventListener) // W3C DOM
		    {
			    elem.addEventListener(evnt, func, false);
		    } else if (elem.attachEvent) // IE DOM
		    {
			    return elem.attachEvent("on" + evnt, func);
		    }
	    },

	    events: {

	        EVENT_GUIDED_ACCESS_CHANGED: 'event_guided_access_changed',
	        EVENT_NETWORK_CONNECTIVITY_CHANGED: 'event_network_connectivity_changed',
	        EVENT_ENTER_BACKGROUND: 'event_enter_background',
	        EVENT_RETURN_FROM_BACKGROUND: 'event_return_from_background',

	        addEventListener: function (_event, _callback) {
	            if (_callback != null && typeof _callback == 'function' &&
                    (_event === this.EVENT_GUIDED_ACCESS_CHANGED
                    || _event === this.EVENT_NETWORK_CONNECTIVITY_CHANGED
                    || _event === this.EVENT_ENTER_BACKGROUND
                    || _event === this.EVENT_RETURN_FROM_BACKGROUND)) {
	                // store the callback
	                AIRMobile.eventsCallbackId.set(_event, _callback);
	            }
	        },

	        onEventDispatched: function (_parameters) {
	            if (_parameters != null) {
	                var results = JSON.parse(_parameters, null);
                    if (results != null && results.event != null) {
                        if (AIRMobile.eventsCallbackId.has(results.event)) {
                            var callbackFunc = AIRMobile.eventsCallbackId.get(results.event);
                            delete results.event;
                            if (callbackFunc != null && typeof callbackFunc == 'function') {
                                callbackFunc(results);
                            }
                        }
	                }
	            }
	        }
	    },
        
        settings : {
            appStartTime: 'unknown',
        },
    
	    /** @namespace Represents security methods for the device */
	     security : {

	        isEnvironmentSecure: function (_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.isEnvironmentSecure.postMessage(messgeToPost);
                }
	        },

	        onIsEnvironmentSecure: function (_parameters) {
	            var results;

	            results = JSON.parse(_parameters, null);
	            var identifier = results.identifier;
	            delete results.identifier;
                if (results.secure === 'true') {
                    results.secure = true;
                } else {
                    results.secure = false;
                }
	            AIRMobile.executeCallback(results, identifier);
	        },

            lockDown: function (enable, _callbackSuccess, _callbackFailure) {

                var identifierSuccess = AIRMobile.UUID();
                var identifierFailure = AIRMobile.UUID();

                if (_callbackSuccess != null && typeof _callbackSuccess == 'function') {
                    AIRMobile.callbacks[identifierSuccess] = _callbackSuccess;
                }
                if (_callbackFailure != null && typeof _callbackFailure == 'function') {
                    AIRMobile.callbacks[identifierFailure] = _callbackFailure;
                }

                var messgeToPost = { 'enable': enable ? 'true' : 'false', 'identifierSuccess': identifierSuccess, 'identifierFailure': identifierFailure };
                window.webkit.messageHandlers.lockDown.postMessage(messgeToPost);

            },

            onLockDownBrowser: function (_parameters) {
                var results, callback;

                results = JSON.parse(_parameters, null);

                if (results.state === 'true') {
                    callback = (results.identifierSuccess != null) ? AIRMobile.callbacks[results.identifierSuccess] : null;
                } else {
                    callback = (results.identifierFailure != null) ? AIRMobile.callbacks[results.identifierFailure] : null;
                }

                if (results.identifierSuccess != null) {
                    delete AIRMobile.callbacks[results.identifierSuccess];
                }
                if (results.identifierFailure != null) {
                    delete AIRMobile.callbacks[results.identifierFailure];
                }

                var isBrowserLocked = results.enabled;
                if (callback != null && typeof callback == 'function') {
                    callback(isBrowserLocked);
                }
            },

            setAltStartPage: function (_url) {
                if (_url != null && _url != '') {
                    var messgeToPost = { 'url': _url };
                    window.webkit.messageHandlers.setAltStartPage.postMessage(messgeToPost);
                }
            },

            restoreDefaultStartPage: function () {
                var messgeToPost = { };
                window.webkit.messageHandlers.restoreDefaultStartPage.postMessage(messgeToPost);
            },

            examineProcessList: function (_blacklistedProcessList, _callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var blacklist = (_blacklistedProcessList != null) ? _blacklistedProcessList : [];
                    var messgeToPost = { 'identifier': identifier, 'blacklist': blacklist };
                    window.webkit.messageHandlers.examineProcessList.postMessage(messgeToPost);
                }
            },

            onExamineProcessList : function (_parameters) {
                var results;
                results = JSON.parse(_parameters, null);
                var identifier = results.identifier;
                delete results.identifier;
                var blacklist = (results.blacklist != null) ? results.blacklist : [];
                AIRMobile.executeCallback(blacklist, identifier);
            },

            /** This function is a placeholder and does not perform any actions. It's presence is
            * only to comply with API certification.
            */
            emptyClipBoard: function() {
        	    // Do nothing, this function is intentionally left blank.
            },
             
            getCapability: function(_feature) {
                var result = {};
                if (_feature ==  null || _feature == '') {
                    return result;
                } else if (_feature === 'text_to_speech' || _feature === 'audio_recorder') {
                    result = { _feature: true };
                    return result;
                } else {
                    result = { _feature: false };
                    return result;
                }
            },
            
             /** This function is a placeholder and does not perform any actions. It's presence is
              * only to comply with API certification.
              */
            setCapability: function(_feature, _value, _successCallback, errorCallback) {
                
            },

            /** Requests the devices mac address
            @return returns a MAC address string
	 	    */
            getMACAddress : function() {
                return AIRMobile.device.macAddress;
            },

            /** returns a comma seperated list of ip addresses
            @return returns a comma seperated ip address string
	 	    */
            getIPAddressList : function() {
                return AIRMobile.device.ipAddress;
            },

            /** Returns a comma seperated list of running processes
            @return returns a comma seperated process list string
	 	    */
            getProcessList : function() {
                return AIRMobile.device.runningProcesses;
            },

            /** This function is a placeholder and does not perform any actions. It's presence is
            * only to comply with API certification.
            */
            close : function(_restart) {

            },

            /** Returns the time that the app was launched
            @return returns a timestamp string
	 	    */
            getStartTime : function() {
                return AIRMobile.settings.startTime;
            },

            /** Retrieve device details. This method is called to retrieve detailed information about a device.
            * The returned data includes teh manufacturer name, device model number (with hardware revision number if available),
            * and OS version (major, minor, and build number). The format of this string is '<key>=<value>' pairs seperated by the '|'
            * symbol. The valid keys are 'Manufacturer', 'HWVer', and 'SWVer'.
            */
            getDeviceInfo: function (_callback) {

                if (_callback != null && typeof _callback == 'function') {
                    var deviceInfo = {
                        'os': 'iOS',
                        'name': 'iOS',
                        'version': AIRMobile.device.operatingSystemVersion,
                        'brand': AIRMobile.device.brand,
                        'model': AIRMobile.device.model,
                        'manufacturer': AIRMobile.device.manufacturer
                    };

                    _callback(deviceInfo);
                }
            }

        },
    
        /** @namespace Represents text to speech functions for the device */
        tts : {
       
            speak: function(_textToSpeak, _options, _callback) {
                
                if (typeof _textToSpeak !== 'string') {
                    return;
                }
                if (_options == null) {
                    _options = {};
                }
                var identifier = AIRMobile.UUID();
                if (_callback != null && typeof _callback == 'function') {
                    AIRMobile.callbacks[identifier] = _callback;
                    AIRMobile.ttsCallbackId = identifier;
                }
                var messgeToPost = { 'identifier': identifier, 'text': _textToSpeak, 'options': JSON.stringify(_options, null, true) };
                window.webkit.messageHandlers.ttsSpeak.postMessage(messgeToPost);
            },
        
            stop: function(_callback) {
                
                var identifier = AIRMobile.UUID();
                if (_callback != null && typeof _callback == 'function') {
                    AIRMobile.callbacks[identifier] = _callback;
                }
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.ttsStop.postMessage(messgeToPost);
                if (AIRMobile.ttsCallbackId != null) {
                    delete AIRMobile.callbacks[AIRMobile.ttsCallbackId];
                    AIRMobile.ttsCallbackId = null;
                }
            },
        
            getStatus: function(_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.ttsGetStatus.postMessage(messgeToPost);
                }
            },

            pause: function (_callback) {
                
                var identifier = AIRMobile.UUID();
                if (_callback != null && typeof _callback == 'function') {
                    AIRMobile.callbacks[identifier] = _callback;
                }
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.ttsPause.postMessage(messgeToPost);
            },

            resume: function (_callback) {
                
                var identifier = AIRMobile.UUID();
                if (_callback != null && typeof _callback == 'function') {
                    AIRMobile.callbacks[identifier] = _callback;
                }
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.ttsResume.postMessage(messgeToPost);
            },

            getVoices: function(_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.getVoices.postMessage(messgeToPost);
                }
            },

            onGetVoices: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results.voices, identifier);
            },

            onTTSStatus: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results.state, identifier);
            },

            onTTSSynchronized: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                if (AIRMobile.ttsCallbackId != null) callback = AIRMobile.callbacks[AIRMobile.ttsCallbackId];

                if (callback != null && typeof callback == 'function') {
                    callback(results);
                }
            },
        },

        recorder: {

            initialize: function (_callback) {

                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.initializeRecorder.postMessage(messgeToPost);
                }
            },

            onInitialized: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results.state, identifier);
            },

            getCapabilities: function (_callback) {

                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.getRecorderCapabilities.postMessage(messgeToPost);
                }
            },

            onGetCapabilities: function(_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results.capabilities, identifier);
            },

            getStatus: function (_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.getRecorderStatus.postMessage(messgeToPost);
                }
            },

            startCapture: function (_options, _callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    AIRMobile.recorderCallbackId = identifier;
                    var messgeToPost = { 'options': JSON.stringify(_options, null, true) };
                    window.webkit.messageHandlers.startCapture.postMessage(messgeToPost);
                }
            },

            onRecorderStatus: function (_parameters) {
                var results;
                results = JSON.parse(_parameters, null);

                var identifier = (results.identifier) ? results.identifier : AIRMobile.recorderCallbackId;
                var persistent = true;
                if (results.type === 'END') {
                    AIRMobile.recorderCallbackId = null;
                    persistent = false;
                }
                delete results.identifier;
                AIRMobile.executeCallback(results, identifier, persistent);
            },

            onGetRecorderStatus: function(_parameters) {
                var results;
                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results.status, identifier);
            },

            stopCapture: function () {
                var messgeToPost = {};
                window.webkit.messageHandlers.stopCapture.postMessage(messgeToPost);
            },

            retrieveAudioRecordingList: function (_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.retrieveAudioFiles.postMessage(messgeToPost);
                }
            },

            onRetrieveAudioFiles: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                AIRMobile.executeCallback(results, identifier);
            },

            retrieveAudioRecording: function (_recordingId, _callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'filename': _recordingId, 'identifier': identifier };
                    window.webkit.messageHandlers.retrieveAudioFile.postMessage(messgeToPost);
                }
            },

            onRetrieveAudioFile: function (_parameters) {
                var results;

                results = JSON.parse(_parameters, null);

                var identifier = results.identifier;
                delete results.identifier;
                if (results.audioInfo != null) {
                    AIRMobile.executeCallback(results.audioInfo, identifier);
                }
            },

            removeAudioRecordings: function (_callback) {
                if (_callback != null && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    var messgeToPost = { 'identifier': identifier };
                    window.webkit.messageHandlers.removeAudioFiles.postMessage(messgeToPost);
                }
            },

            play: function (_audioInfo, _callback) {
                if (typeof _audioInfo == 'object' && typeof _callback == 'function') {
                    var identifier = AIRMobile.UUID();
                    AIRMobile.callbacks[identifier] = _callback;
                    AIRMobile.audioCallbackId = identifier;
                    var messgeToPost = { 'identifier': identifier, 'audioInfo': _audioInfo };
                    window.webkit.messageHandlers.audioPlay.postMessage(messgeToPost);
                }
            },

            stopPlay: function () {
                var identifier = AIRMobile.UUID();
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.audioStop.postMessage(messgeToPost);
            },

            pausePlay: function () {
                var identifier = AIRMobile.UUID();
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.audioPause.postMessage(messgeToPost);
            },

            resumePlay: function () {
                var identifier = AIRMobile.UUID();
                var messgeToPost = { 'identifier': identifier };
                window.webkit.messageHandlers.audioResume.postMessage(messgeToPost);
            },

            onAudioPlaybackStatus: function (_parameters) {
                var results;
                results = JSON.parse(_parameters, null);

                var identifier = (results.identifier) ? results.identifier : AIRMobile.audioCallbackId;
                delete results.identifier;
                var persistent = !(results.state === 'PLAYBACK_END' || results.state === 'PLAYBACK_STOPPED');
                AIRMobile.executeCallback(results, identifier, persistent);
            }

        }

    };

    /********************** CODE FROM SUMMIT   ********************/
    window.SecureBrowser = AIRMobile;

    this.getNativeBrowser = function () { return AIRMobile; };
};

(new MSB()).getNativeBrowser().initialize();
