//
//  Header.h
//  VT_Example
//
//  Created by 강 성훈 on 11. 12. 15..
//  Copyright 2011년 보이스웨어. All rights reserved.
//


//Language & TTS Voice Setting///////////////////
#define __ENG__                 // TTS LANGUAGE
#define __JULIE__             // TTS VOICE
//#define __SPA__                 // TTS LANGUAGE
//#define __VIOLETA__             // TTS VOICE
/////////////////////////////////////////////////

#if defined (__BRE__)
    #if defined (__BRIDGET__)
        #import "vt_bre_bridget.h"
        #define VT_TextToBuffer VT_TextToBuffer_BRE_Bridget
        #define VT_LOADTTS VT_LOADTTS_BRE_Bridget
        #define VT_UNLOADTTS VT_UNLOADTTS_BRE_Bridget
    #endif
#endif

#if defined (__CFR__)
    #if defined (__CHLOE__)
        #import "vt_cfr_chloe.h"
        #define VT_TextToBuffer VT_TextToBuffer_CFR_Chloe
        #define VT_LOADTTS VT_LOADTTS_CFR_Chloe
        #define VT_UNLOADTTS VT_UNLOADTTS_CFR_Chloe
    #endif
#endif

#if defined (__CHI__)
    #if defined (__HUI__)
        #import "vt_chi_hui.h"
        #define VT_TextToBuffer VT_TextToBuffer_CHI_Hui
        #define VT_LOADTTS VT_LOADTTS_CHI_Hui
        #define VT_UNLOADTTS VT_UNLOADTTS_CHI_Hui
    #endif
    #if defined (__LIANG__)
        #import "vt_chi_liang.h"
        #define VT_TextToBuffer VT_TextToBuffer_CHI_Liang
        #define VT_LOADTTS VT_LOADTTS_CHI_Liang
        #define VT_UNLOADTTS VT_UNLOADTTS_CHI_Liang
    #endif    
#endif

#if defined (__ENG__)
    #if defined (__JAMES__)
        #import "vt_eng_james.h"
        #define VT_TextToBuffer VT_TextToBuffer_ENG_James
        #define VT_LOADTTS VT_LOADTTS_ENG_James
        #define VT_UNLOADTTS VT_UNLOADTTS_ENG_James
    #endif
    #if defined (__JULIE__)
        #import "vt_eng_julie.h"
        #define VT_TextToBuffer VT_TextToBuffer_ENG_Julie
        #define VT_LOADTTS VT_LOADTTS_ENG_Julie
        #define VT_UNLOADTTS VT_UNLOADTTS_ENG_Julie
    #endif
    #if defined (__KATE__)
        #import "vt_eng_kate.h"
        #define VT_TextToBuffer VT_TextToBuffer_ENG_Kate
        #define VT_LOADTTS VT_LOADTTS_ENG_Kate
        #define VT_UNLOADTTS VT_UNLOADTTS_ENG_Kate
    #endif
        #if defined (__PAUL__)
        #import "vt_eng_paul.h"
        #define VT_TextToBuffer VT_TextToBuffer_ENG_Paul
        #define VT_LOADTTS VT_LOADTTS_ENG_Paul
        #define VT_UNLOADTTS VT_UNLOADTTS_ENG_Paul
    #endif    
#endif

#if defined (__JPN__)
    #if defined (__HARUKA__)
        #import "vt_jpn_haruka.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Haruka
        #define VT_LOADTTS VT_LOADTTS_JPN_Haruka
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Haruka
    #endif
    #if defined (__HIKARI__)
        #import "vt_jpn_hikari.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Hikari
        #define VT_LOADTTS VT_LOADTTS_JPN_Hikari
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Hikari
    #endif
    #if defined (__MISAKI__)
        #import "vt_jpn_misaki.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Misaki
        #define VT_LOADTTS VT_LOADTTS_JPN_Misaki
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Misaki
    #endif
    #if defined (__RYO__)
        #import "vt_jpn_ryo.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Ryo
        #define VT_LOADTTS VT_LOADTTS_JPN_Ryo
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Ryo
    #endif
    #if defined (__SAYAKA__)
        #import "vt_jpn_sayaka.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Sayaka
        #define VT_LOADTTS VT_LOADTTS_JPN_Sayaka
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Sayaka
    #endif
    #if defined (__SHOW__)
        #import "vt_jpn_show.h"
        #define VT_TextToBuffer VT_TextToBuffer_JPN_Show
        #define VT_LOADTTS VT_LOADTTS_JPN_Show
        #define VT_UNLOADTTS VT_UNLOADTTS_JPN_Show
    #endif             
#endif

#if defined (__KOR__)
    #if defined (__HYERYUN__)
        #import "vt_kor_hyeryun.h"
        #define VT_TextToBuffer VT_TextToBuffer_KOR_Hyeryun
        #define VT_LOADTTS VT_LOADTTS_KOR_Hyeryun
        #define VT_UNLOADTTS VT_UNLOADTTS_KOR_Hyeryun
#endif
    #if defined (__YUMI__)
        #import "vt_kor_yumi.h"
        #define VT_TextToBuffer VT_TextToBuffer_KOR_Yumi
        #define VT_LOADTTS VT_LOADTTS_KOR_Yumi
        #define VT_UNLOADTTS VT_UNLOADTTS_KOR_Yumi
    #endif
    #if defined (__JUNWOO__)
        #import "vt_kor_junwoo.h"
        #define VT_TextToBuffer VT_TextToBuffer_KOR_Junwoo
        #define VT_LOADTTS VT_LOADTTS_KOR_Junwoo
        #define VT_UNLOADTTS VT_UNLOADTTS_KOR_Junwoo
    #endif
#endif

#if defined (__SPA__)
    #if defined (__VIOLETA__)
        #import "vt_spa_violeta.h"
        #define VT_TextToBuffer VT_TextToBuffer_SPA_Violeta
        #define VT_LOADTTS VT_LOADTTS_SPA_Violeta
        #define VT_UNLOADTTS VT_UNLOADTTS_SPA_Violeta
    #endif
#endif