//---------------------------------------------------------------------------
// Copyright (C) 2005 Dallas Semiconductor Corporation, All Rights Reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL DALLAS SEMICONDUCTOR BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// Except as contained in this notice, the name of Dallas Semiconductor
// shall not be used except as stated in the Dallas Semiconductor
// Branding Policy.
//--------------------------------------------------------------------------
//
//  PDKAdapterUSB.c - Implements native jni interface to PDK libUSB build
//  version 2.00

#include "PDKAdapterUSB.h"
#include "ownet.h"

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_OpenPort
  (JNIEnv * env, jobject obj, jstring portDesc)
{
   /* Convert to UTF8 */
   const char *portDescUTF;
  
   printf("PDKAdapter.OpenPort_native called\n");
   portDescUTF  = (*env)->GetStringUTFChars(env, portDesc, JNI_FALSE);
   printf("opening %s\n", portDescUTF);
  
   /* Call into external dylib function */
   jint rc = owAcquireEx((char*)portDescUTF);
  
   /* Release created UTF8 string */
   (*env)->ReleaseStringUTFChars(env, portDesc, portDescUTF);

   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return rc;
}

JNIEXPORT void JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_ClosePort
  (JNIEnv * env, jobject obj, jint portHandle)
{
   printf("calling owRelease\n");
   owRelease(portHandle);
   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_Reset
  (JNIEnv * env, jobject obj, jint portHandle)
{
   jint ret = owTouchReset(portHandle);
   if(!ret)
   {
      int errorNum = owGetErrorNum();
      if(errorNum==OWERROR_OW_SHORTED)
      	ret = com_dalsemi_onewire_adapter_PDKAdapterUSB_RESET_SHORT;
      else if(errorNum==OWERROR_RESET_FAILED)
      	ret = -1;
      else
         ret = com_dalsemi_onewire_adapter_PDKAdapterUSB_RESET_NOPRESENCE;
   }
   else
      ret = com_dalsemi_onewire_adapter_PDKAdapterUSB_RESET_PRESENCE;

   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_DataBlock
  (JNIEnv * env, jobject obj, jint portHandle, jbyteArray buff, jint off, jint len)
{
   jint ret = 1;
   jboolean is_copy;
   jbyte *buffLocal;
   
   jsize arrayLength = (*env)->GetArrayLength(env, buff);
   if(off+len>arrayLength)
      return -1;
      
   buffLocal = (*env)->GetByteArrayElements(env, buff, &is_copy);

   if(!owBlock(portHandle, FALSE, &buffLocal[off], len))
      ret = -1;
   else
      (*env)->SetByteArrayRegion(env, buff, off, len, &buffLocal[off]);

   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_TouchByte
  (JNIEnv * env, jobject obj, jint portHandle, jint dataByte)
{
   jint ret = -1;
   
   ret = owTouchByte(portHandle, (SMALLINT)dataByte);
   
   if(owHasErrors() && owGetErrorNum()==OWERROR_ADAPTER_ERROR)
      ret = -1;
      
   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_TouchBytePower
  (JNIEnv * env, jobject obj, jint portHandle, jint dataByte)
{
   jint ret = -1;
   
   ret = owTouchBytePower(portHandle, (SMALLINT)dataByte);
   
   if(owHasErrors() && owGetErrorNum()==OWERROR_ADAPTER_ERROR)
      ret = -1;
      
   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_TouchBit
  (JNIEnv * env, jobject obj, jint portHandle, jint dataBit)
{
   jint ret = -1;
   
   ret = owTouchBit(portHandle, (SMALLINT)dataBit);
   
   if(owHasErrors() && owGetErrorNum()==OWERROR_ADAPTER_ERROR)
      ret = -1;
      
   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

// this method is wrong, readBitPower doesn't do what's intended
JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_TouchBitPower
  (JNIEnv * env, jobject obj, jint portHandle, jint dataBit)
{
   jint ret = -1;
   
   ret = owReadBitPower(portHandle, (SMALLINT)dataBit);
   
   if(owHasErrors() && owGetErrorNum()==OWERROR_ADAPTER_ERROR)
      ret = -1;
      
   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jboolean JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_AdapterDetected
  (JNIEnv *env, jobject obj, jint portHandle)
{
   int ret = AdapterRecover(portHandle);

   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   if(ret)
      return JNI_TRUE;
   else
      return JNI_FALSE;
}

JNIEXPORT void JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_GetAddress
  (JNIEnv * env, jobject obj, jint portHandle, jbyteArray addr)
{
   uchar buff[8];
   owSerialNum(portHandle, buff, TRUE);
   (*env)->SetByteArrayRegion(env, addr, 0, 8, buff);
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_Search
  (JNIEnv * env, jobject obj, jint portHandle, jboolean findFirst, 
  jboolean doReset, jboolean alarmOnly)
{
   int ret = -1;
   if(findFirst)
      ret = owFirst(portHandle, doReset, alarmOnly);
   else
      ret = owNext(portHandle, doReset, alarmOnly);
   if(!ret && owHasErrors() && owGetErrorNum()!=OWERROR_NO_DEVICES_ON_NET)
      ret = -1;

   // flush remaining errors
   while(owHasErrors()) owGetErrorNum();   

   return ret;
}

JNIEXPORT jint JNICALL Java_com_dalsemi_onewire_adapter_PDKAdapterUSB_PowerLevel
  (JNIEnv * env, jobject obj, jint portHandle, jint newLevel)
{
	int ret = 0;
	if(newLevel==com_dalsemi_onewire_adapter_PDKAdapterUSB_LEVEL_NORMAL)
		ret = (MODE_NORMAL==owLevel(portHandle, MODE_NORMAL))?1:0;
	else if(newLevel==com_dalsemi_onewire_adapter_PDKAdapterUSB_LEVEL_POWER_DELIVERY)
		ret = (MODE_STRONG5==owLevel(portHandle, MODE_STRONG5))?1:0;
    
    if(ret==0)
    {
       if(owHasErrors())
          ret = -1;
    }
    
    // flush remaining errors
    while(owHasErrors()) owGetErrorNum();
    
	return ret;
}

