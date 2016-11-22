/* Automatically generated by
	SmartSyntaxPluginCodeGenerator VMMaker.oscog-nice.1989 uuid: 7e63fa13-3564-4b1b-8c0b-31378a87bc74
   from
	SerialPlugin VMMaker.oscog-nice.1989 uuid: 7e63fa13-3564-4b1b-8c0b-31378a87bc74
 */
static char __buildInfo[] = "SerialPlugin VMMaker.oscog-nice.1989 uuid: 7e63fa13-3564-4b1b-8c0b-31378a87bc74 " __DATE__ ;



#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
#include "sqConfig.h"			/* Configuration options */
#include "sqVirtualMachine.h"	/*  The virtual machine proxy definition */
#include "sqPlatformSpecific.h"	/* Platform specific definitions */

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
# undef EXPORT
# define EXPORT(returnType) static returnType
#endif

#include "SerialPlugin.h"
#include "sqMemoryAccess.h"


/*** Function Prototypes ***/
EXPORT(const char*) getModuleName(void);
EXPORT(sqInt) initialiseModule(void);
EXPORT(sqInt) primitiveSerialPortClose(void);
EXPORT(sqInt) primitiveSerialPortOpen(void);
#if PharoVM
EXPORT(sqInt) primitiveSerialPortOpenByName(void);
#endif /* PharoVM */
EXPORT(sqInt) primitiveSerialPortRead(void);
#if PharoVM
EXPORT(sqInt) primitiveSerialPortReadByName(void);
#endif /* PharoVM */
EXPORT(sqInt) primitiveSerialPortWrite(void);
#if PharoVM
EXPORT(sqInt) primitiveSerialPortWriteByName(void);
#endif /* PharoVM */
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
EXPORT(sqInt) shutdownModule(void);
static sqInt sqAssert(sqInt aBool);


/*** Variables ***/

#if !defined(SQUEAK_BUILTIN_PLUGIN)
static sqInt (*byteSizeOf)(sqInt oop);
static sqInt (*failed)(void);
static void * (*firstIndexableField)(sqInt oop);
static sqInt (*integerObjectOf)(sqInt value);
static sqInt (*isBytes)(sqInt oop);
static sqInt (*pop)(sqInt nItems);
static sqInt (*popthenPush)(sqInt nItems, sqInt oop);
static sqInt (*slotSizeOf)(sqInt oop);
static sqInt (*stackIntegerValue)(sqInt offset);
static sqInt (*stackValue)(sqInt offset);
static sqInt (*success)(sqInt aBoolean);
#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */
extern sqInt byteSizeOf(sqInt oop);
extern sqInt failed(void);
extern void * firstIndexableField(sqInt oop);
extern sqInt integerObjectOf(sqInt value);
extern sqInt isBytes(sqInt oop);
extern sqInt pop(sqInt nItems);
extern sqInt popthenPush(sqInt nItems, sqInt oop);
extern sqInt slotSizeOf(sqInt oop);
extern sqInt stackIntegerValue(sqInt offset);
extern sqInt stackValue(sqInt offset);
extern sqInt success(sqInt aBoolean);
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SerialPlugin VMMaker.oscog-nice.1989 (i)"
#else
	"SerialPlugin VMMaker.oscog-nice.1989 (e)"
#endif
;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

	/* InterpreterPlugin>>#getModuleName */
EXPORT(const char*)
getModuleName(void)
{
	return moduleName;
}

	/* SerialPlugin>>#initialiseModule */
EXPORT(sqInt)
initialiseModule(void)
{
	return serialPortInit();
}

	/* SerialPlugin>>#primitiveSerialPortClose: */
EXPORT(sqInt)
primitiveSerialPortClose(void)
{
	sqInt portNum;

	portNum = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	serialPortClose(portNum);
	if (failed()) {
		return null;
	}
	pop(1);
	return null;
}

	/* SerialPlugin>>#primitiveSerialPortOpen:baudRate:stopBitsType:parityType:dataBits:inFlowControlType:outFlowControlType:xOnByte:xOffByte: */
EXPORT(sqInt)
primitiveSerialPortOpen(void)
{
	sqInt baudRate;
	sqInt dataBits;
	sqInt inFlowControl;
	sqInt outFlowControl;
	sqInt parityType;
	sqInt portNum;
	sqInt stopBitsType;
	sqInt xOffChar;
	sqInt xOnChar;

	portNum = stackIntegerValue(8);
	baudRate = stackIntegerValue(7);
	stopBitsType = stackIntegerValue(6);
	parityType = stackIntegerValue(5);
	dataBits = stackIntegerValue(4);
	inFlowControl = stackIntegerValue(3);
	outFlowControl = stackIntegerValue(2);
	xOnChar = stackIntegerValue(1);
	xOffChar = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	serialPortOpen(
			portNum, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar);
	if (failed()) {
		return null;
	}
	pop(9);
	return null;
}

	/* SerialPlugin>>#primitiveSerialPortOpenByName:baudRate:stopBitsType:parityType:dataBits:inFlowControlType:outFlowControlType:xOnByte:xOffByte: */
#if PharoVM
EXPORT(sqInt)
primitiveSerialPortOpenByName(void)
{
	sqInt baudRate;
	sqInt dataBits;
	sqInt inFlowControl;
	sqInt outFlowControl;
	sqInt parityType;
	char *port;
	char *portName;
	sqInt portNameSize;
	sqInt stopBitsType;
	sqInt xOffChar;
	sqInt xOnChar;

	success(isBytes(stackValue(8)));
	portName = ((char *) (firstIndexableField(stackValue(8))));
	baudRate = stackIntegerValue(7);
	stopBitsType = stackIntegerValue(6);
	parityType = stackIntegerValue(5);
	dataBits = stackIntegerValue(4);
	inFlowControl = stackIntegerValue(3);
	outFlowControl = stackIntegerValue(2);
	xOnChar = stackIntegerValue(1);
	xOffChar = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	portNameSize = slotSizeOf(((sqInt)((portName) - BaseHeaderSize)));
	port = calloc(portNameSize+1, sizeof(char));
	memcpy(port, portName, portNameSize);
	serialPortOpenByName(
			port, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar);
	free(port);
	if (failed()) {
		return null;
	}
	pop(9);
	return null;
}
#endif /* PharoVM */

	/* SerialPlugin>>#primitiveSerialPortRead:into:startingAt:count: */
EXPORT(sqInt)
primitiveSerialPortRead(void)
{
	char *array;
	sqInt arrayPtr;
	sqInt bytesRead;
	sqInt count;
	sqInt portNum;
	sqInt startIndex;
	sqInt _return_value;

	portNum = stackIntegerValue(3);
	success(isBytes(stackValue(2)));
	array = ((char *) (firstIndexableField(stackValue(2))));
	startIndex = stackIntegerValue(1);
	count = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	success((startIndex >= 1)
	 && (((startIndex + count) - 1) <= (byteSizeOf(((sqInt)(sqIntptr_t)(array) - BaseHeaderSize)))));
	arrayPtr = ((((sqInt)array)) + startIndex) - 1;
	bytesRead = serialPortReadInto( portNum, count, arrayPtr);
	if (failed()) {
		return null;
	}
	_return_value = integerObjectOf(bytesRead);
	if (failed()) {
		return null;
	}
	popthenPush(5, _return_value);
	return null;
}

	/* SerialPlugin>>#primitiveSerialPortReadByName:into:startingAt:count: */
#if PharoVM
EXPORT(sqInt)
primitiveSerialPortReadByName(void)
{
	char *array;
	char * arrayPtr;
	sqInt bytesRead;
	sqInt count;
	char *port;
	char *portName;
	sqInt portNameSize;
	sqInt startIndex;
	sqInt _return_value;

	success(isBytes(stackValue(3)));
	portName = ((char *) (firstIndexableField(stackValue(3))));
	success(isBytes(stackValue(2)));
	array = ((char *) (firstIndexableField(stackValue(2))));
	startIndex = stackIntegerValue(1);
	count = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	success((startIndex >= 1)
	 && (((startIndex + count) - 1) <= (byteSizeOf(((sqInt)(sqIntptr_t)(array) - BaseHeaderSize)))));
	portNameSize = slotSizeOf(((sqInt)((portName) - BaseHeaderSize)));
	port = calloc(portNameSize+1, sizeof(char));
	memcpy(port, portName, portNameSize);
	arrayPtr = (array + startIndex) - 1;
	bytesRead = serialPortReadIntoByName( port, count, arrayPtr);
	free(port);
	if (failed()) {
		return null;
	}
	_return_value = integerObjectOf(bytesRead);
	if (failed()) {
		return null;
	}
	popthenPush(5, _return_value);
	return null;
}
#endif /* PharoVM */

	/* SerialPlugin>>#primitiveSerialPortWrite:from:startingAt:count: */
EXPORT(sqInt)
primitiveSerialPortWrite(void)
{
	char *array;
	char * arrayPtr;
	sqInt bytesWritten;
	sqInt count;
	sqInt portNum;
	sqInt startIndex;
	sqInt _return_value;

	bytesWritten = 0;
	portNum = stackIntegerValue(3);
	success(isBytes(stackValue(2)));
	array = ((char *) (firstIndexableField(stackValue(2))));
	startIndex = stackIntegerValue(1);
	count = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	success((startIndex >= 1)
	 && (((startIndex + count) - 1) <= (byteSizeOf(((sqInt)(sqIntptr_t)(array) - BaseHeaderSize)))));
	if (!(failed())) {
		arrayPtr = (array + startIndex) - 1;
		bytesWritten = serialPortWriteFrom(portNum, count, arrayPtr);
	}
	if (failed()) {
		return null;
	}
	_return_value = integerObjectOf(bytesWritten);
	if (failed()) {
		return null;
	}
	popthenPush(5, _return_value);
	return null;
}

	/* SerialPlugin>>#primitiveSerialPortWriteByName:from:startingAt:count: */
#if PharoVM
EXPORT(sqInt)
primitiveSerialPortWriteByName(void)
{
	char *array;
	char * arrayPtr;
	sqInt bytesWritten;
	sqInt count;
	char *port;
	char *portName;
	sqInt portNameSize;
	sqInt startIndex;
	sqInt _return_value;

	bytesWritten = 0;
	success(isBytes(stackValue(3)));
	portName = ((char *) (firstIndexableField(stackValue(3))));
	success(isBytes(stackValue(2)));
	array = ((char *) (firstIndexableField(stackValue(2))));
	startIndex = stackIntegerValue(1);
	count = stackIntegerValue(0);
	if (failed()) {
		return null;
	}
	portNameSize = slotSizeOf(((sqInt)((portName) - BaseHeaderSize)));
	port = calloc(portNameSize+1, sizeof(char));
	memcpy(port, portName, portNameSize);
	success((startIndex >= 1)
	 && (((startIndex + count) - 1) <= (byteSizeOf(((sqInt)(sqIntptr_t)(array) - BaseHeaderSize)))));
	if (!(failed())) {
		arrayPtr = (array + startIndex) - 1;
		bytesWritten = serialPortWriteFromByName(port, count, arrayPtr);
	}
	free(port);
	if (failed()) {
		return null;
	}
	_return_value = integerObjectOf(bytesWritten);
	if (failed()) {
		return null;
	}
	popthenPush(5, _return_value);
	return null;
}
#endif /* PharoVM */


/*	Note: This is coded so that it can be run in Squeak. */

	/* InterpreterPlugin>>#setInterpreter: */
EXPORT(sqInt)
setInterpreter(struct VirtualMachine*anInterpreter)
{
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = ((interpreterProxy->majorVersion()) == (VM_PROXY_MAJOR))
	 && ((interpreterProxy->minorVersion()) >= (VM_PROXY_MINOR));
	if (ok) {
		
#if !defined(SQUEAK_BUILTIN_PLUGIN)
		byteSizeOf = interpreterProxy->byteSizeOf;
		failed = interpreterProxy->failed;
		firstIndexableField = interpreterProxy->firstIndexableField;
		integerObjectOf = interpreterProxy->integerObjectOf;
		isBytes = interpreterProxy->isBytes;
		pop = interpreterProxy->pop;
		popthenPush = interpreterProxy->popthenPush;
		slotSizeOf = interpreterProxy->slotSizeOf;
		stackIntegerValue = interpreterProxy->stackIntegerValue;
		stackValue = interpreterProxy->stackValue;
		success = interpreterProxy->success;
#endif /* !defined(SQUEAK_BUILTIN_PLUGIN) */
	}
	return ok;
}

	/* SerialPlugin>>#shutdownModule */
EXPORT(sqInt)
shutdownModule(void)
{
	return serialPortShutdown();
}

	/* SmartSyntaxInterpreterPlugin>>#sqAssert: */
static sqInt
sqAssert(sqInt aBool)
{
	/* missing DebugCode */;
	return aBool;
}


#ifdef SQUEAK_BUILTIN_PLUGIN

static char _m[] = "SerialPlugin";
void* SerialPlugin_exports[][3] = {
	{(void*)_m, "getModuleName", (void*)getModuleName},
	{(void*)_m, "initialiseModule", (void*)initialiseModule},
	{(void*)_m, "primitiveSerialPortClose\000\000", (void*)primitiveSerialPortClose},
	{(void*)_m, "primitiveSerialPortOpen\000\000", (void*)primitiveSerialPortOpen},
#if PharoVM
	{(void*)_m, "primitiveSerialPortOpenByName\000\000", (void*)primitiveSerialPortOpenByName},
#endif /* PharoVM */
	{(void*)_m, "primitiveSerialPortRead\000\000", (void*)primitiveSerialPortRead},
#if PharoVM
	{(void*)_m, "primitiveSerialPortReadByName\000\000", (void*)primitiveSerialPortReadByName},
#endif /* PharoVM */
	{(void*)_m, "primitiveSerialPortWrite\000\000", (void*)primitiveSerialPortWrite},
#if PharoVM
	{(void*)_m, "primitiveSerialPortWriteByName\000\000", (void*)primitiveSerialPortWriteByName},
#endif /* PharoVM */
	{(void*)_m, "setInterpreter", (void*)setInterpreter},
	{(void*)_m, "shutdownModule\000\377", (void*)shutdownModule},
	{NULL, NULL, NULL}
};

#else /* ifdef SQ_BUILTIN_PLUGIN */

signed char primitiveSerialPortCloseAccessorDepth = 0;
signed char primitiveSerialPortOpenAccessorDepth = 0;
signed char primitiveSerialPortOpenByNameAccessorDepth = 0;
signed char primitiveSerialPortReadAccessorDepth = 0;
signed char primitiveSerialPortReadByNameAccessorDepth = 0;
signed char primitiveSerialPortWriteAccessorDepth = 0;
signed char primitiveSerialPortWriteByNameAccessorDepth = 0;

#endif /* ifdef SQ_BUILTIN_PLUGIN */
