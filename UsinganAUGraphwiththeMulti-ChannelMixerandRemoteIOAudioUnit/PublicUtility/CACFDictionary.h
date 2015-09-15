/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Part of CoreAudio Utility Classes
*/

#if !defined(__CACFDictionary_h__)
#define __CACFDictionary_h__

//=============================================================================
//	Includes
//=============================================================================

//	System Includes
#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <CoreFoundation/CoreFoundation.h>
#else
	#include <CoreFoundation.h>
#endif

//=============================================================================
//	Types
//=============================================================================

class	CACFArray;
class	CACFString;

//=============================================================================
//	CACFDictionary
//=============================================================================

class CACFDictionary 
{

//	Construction/Destruction
public:
							CACFDictionary(bool inRelease = true)									: mCFDictionary(CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)), mRelease(inRelease), mMutable(true) {}
							CACFDictionary(CFDictionaryRef inCFDictionary, bool inRelease)			: mCFDictionary(const_cast<CFMutableDictionaryRef>(inCFDictionary)), mRelease(inRelease), mMutable(false) {}
							CACFDictionary(CFMutableDictionaryRef inCFDictionary, bool inRelease)	: mCFDictionary(inCFDictionary), mRelease(inRelease), mMutable(true) {}
							CACFDictionary(const CACFDictionary& inDictionary)						: mCFDictionary(inDictionary.mCFDictionary), mRelease(inDictionary.mRelease), mMutable(inDictionary.mMutable) { Retain(); }
	CACFDictionary&			operator=(const CACFDictionary& inDictionary)							{ Release(); mCFDictionary = inDictionary.mCFDictionary; mRelease = inDictionary.mRelease; mMutable = inDictionary.mMutable; Retain(); return *this; } 
	CACFDictionary&			operator=(CFDictionaryRef inDictionary)									{ Release(); mCFDictionary = const_cast<CFMutableDictionaryRef>(inDictionary); mMutable = false; Retain(); return *this; } 
	CACFDictionary&			operator=(CFMutableDictionaryRef inDictionary)							{ Release(); mCFDictionary = inDictionary; mMutable = true; Retain(); return *this; } 
							~CACFDictionary()														{ Release(); }

private:
	void					Retain()																{ if(mRelease && (mCFDictionary != NULL)) { CFRetain(mCFDictionary); } }
	void					Release()																{ if(mRelease && (mCFDictionary != NULL)) { CFRelease(mCFDictionary); } }
		
//	Attributes
public:
	bool					IsValid() const															{ return mCFDictionary != NULL; }
	bool					IsMutable() const														{ return mMutable;}
	bool					CanModify() const														{ return mMutable && (mCFDictionary != NULL); }
	
	bool					WillRelease() const														{ return mRelease; }
	void					ShouldRelease(bool inRelease)											{ mRelease = inRelease; }
	
	CFDictionaryRef			GetDict() const															{ return mCFDictionary; }
	CFDictionaryRef			GetCFDictionary() const													{ return mCFDictionary; }
	CFDictionaryRef			CopyCFDictionary() const												{ if(mCFDictionary != NULL) { CFRetain(mCFDictionary); } return mCFDictionary; }

	CFMutableDictionaryRef	GetMutableDict()														{ return mCFDictionary; }
	CFMutableDictionaryRef	GetCFMutableDictionary() const											{ return mCFDictionary; }
	CFMutableDictionaryRef	CopyCFMutableDictionary() const											{ if(mCFDictionary != NULL) { CFRetain(mCFDictionary); } return mCFDictionary; }
	void					SetCFMutableDictionaryFromCopy(CFDictionaryRef inDictionary, bool inRelease = true)		{ Release(); mCFDictionary = CFDictionaryCreateMutableCopy(NULL, 0, inDictionary); mMutable = true; mRelease = inRelease; }
	void					SetCFMutableDictionaryToEmpty(bool inRelease = true)					{ Release(); mCFDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); mMutable = true; mRelease = inRelease; }

	CFPropertyListRef		AsPropertyList() const													{ return mCFDictionary; }
	OSStatus				GetDictIfMutable(CFMutableDictionaryRef& outDict) const					{ OSStatus theAnswer = -1; if(mMutable) { outDict = mCFDictionary; theAnswer = 0; } return theAnswer; }

//	Item Operations
public:
	bool					HasKey(const CFStringRef inKey) const;
	UInt32					Size() const;
	void					GetKeys(const void** keys) const;
	
	bool					GetBool(const CFStringRef inKey, bool& outValue) const;
	bool					GetSInt32(const CFStringRef inKey, SInt32& outValue) const;
	bool					GetUInt32(const CFStringRef inKey, UInt32& outValue) const;
	bool					GetSInt64(const CFStringRef inKey, SInt64& outValue) const;
	bool					GetUInt64(const CFStringRef inKey, UInt64& outValue) const;
	bool					GetFloat32(const CFStringRef inKey, Float32& outValue) const;
	bool					GetFloat64(const CFStringRef inKey, Float64& outValue) const;
	bool					GetFixed32(const CFStringRef inKey, Float32& outValue) const;
	bool					GetFixed64(const CFStringRef inKey, Float64& outValue) const;
	bool					Get4CC(const CFStringRef inKey, UInt32& outValue) const;
	bool					GetString(const CFStringRef inKey, CFStringRef& outValue) const;	
	bool					GetArray(const CFStringRef inKey, CFArrayRef& outValue) const;	
	bool					GetDictionary(const CFStringRef inKey, CFDictionaryRef& outValue) const;	
	bool					GetData(const CFStringRef inKey, CFDataRef& outValue) const;
	bool					GetCFType(const CFStringRef inKey, CFTypeRef& outValue) const;
	bool					GetURL(const CFStringRef inKey, CFURLRef& outValue) const;
	bool					GetCFTypeWithCStringKey(const char* inKey, CFTypeRef& outValue) const;

	void					GetCACFString(const CFStringRef inKey, CACFString& outItem) const;
	void					GetCACFArray(const CFStringRef inKey, CACFArray& outItem) const;
	void					GetCACFDictionary(const CFStringRef inKey, CACFDictionary& outItem) const;
	
	bool					AddBool(const CFStringRef inKey, bool inValue);
	bool					AddSInt32(const CFStringRef inKey, SInt32 inValue);
	bool					AddUInt32(const CFStringRef inKey, UInt32 inValue);
	bool					AddSInt64(const CFStringRef inKey, SInt64 inValue);
	bool					AddUInt64(const CFStringRef inKey, UInt64 inValue);
	bool					AddFloat32(const CFStringRef inKey, Float32 inValue);
	bool					AddFloat64(const CFStringRef inKey, Float64 inValue);
	bool					AddNumber(const CFStringRef inKey, const CFNumberRef inValue);
	bool					AddString(const CFStringRef inKey, const CFStringRef inValue);
	bool					AddArray(const CFStringRef inKey, const CFArrayRef inValue);
	bool					AddDictionary(const CFStringRef inKey, const CFDictionaryRef inValue);
	bool					AddData(const CFStringRef inKey, const CFDataRef inValue);
	bool					AddCFType(const CFStringRef inKey, const CFTypeRef inValue);
	bool					AddURL(const CFStringRef inKey, const CFURLRef inValue);
	
	bool					AddCFTypeWithCStringKey(const char* inKey, const CFTypeRef inValue);
	bool					AddCString(const CFStringRef inKey, const char* inValue);

	void					RemoveKey(const CFStringRef inKey)										{ if(CanModify()) { CFDictionaryRemoveValue(mCFDictionary, inKey); } }
	void					Clear()																	{ if(CanModify()) { CFDictionaryRemoveAllValues(mCFDictionary); } }
	
	void					Show()																	{ CFShow(mCFDictionary); }
	
//	Implementation
private:
	CFMutableDictionaryRef 	mCFDictionary;
	bool					mRelease;
	bool					mMutable;
};

#endif //__CACFDictionary_h__
