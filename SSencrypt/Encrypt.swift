//Copyright (c) 2016, networkextension
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
//* Redistributions of source code must retain the above copyright notice, this
//list of conditions and the following disclaimer.
//
//* Redistributions in binary form must reproduce the above copyright notice,
//this list of conditions and the following disclaimer in the documentation
//and/or other materials provided with the distribution.
//
//* Neither the name of SSencrypt nor the names of its
//contributors may be used to endorse or promote products derived from
//this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
import Foundation
import Security


//
//  Encrypt.swift
//  Surf
//
//  Created by yarshure on 16/5/12.
//  Copyright © 2016年 yarshure. All rights reserved.
//
// gfw.press support
import Foundation
import Security


//let kChosenCipherBlockSize = kCCBlockSizeAES128
//let kChosenCipherKeySize = kCCKeySizeAES128
//import CryptoSwift
extension String  {
    var md5: String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
}
extension NSData {
    var md5: NSData! {
        //let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        //let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(self.bytes, CC_LONG(self.length), result)
        
        //let hash = NSMutableString()
        //for i in 0..<digestLen {
        //    hash.appendFormat("%02x", result[i])
        //}
        let x = NSData.init(bytes: result, length: digestLen)
        result.dealloc(digestLen)
        
        return x
    }
}
class Encrypt: SSEncrypt{
    static let CHARSET = 0
    static  let BLOCK_MAX_FILE:Int = 64 * 1024 * 1024// 64MB，被加密数据块的字节最大长度，用于文件
    static  let ENCRYPT_SIZE:Int = 30; // 加密数据长度值加密后的字节长度，固定30个字节，解密后固定14个字节
    static  let IV_SIZE:Int = 16; // IV字节长度，16
    static  let NOISE_MAX:Int = 1024 * 4; // 噪音数据最大长度，4K
    
//    private SecureRandom secureRandom = null;
//    private Cipher cipher = null;
//    private KeyGenerator keyGenerator = null;
    
    //var key:NSData? //加密的key
    var leftdataLength:Int = 0
    var lettnoiseLength:Int = 0
    var recv_iv:NSData?
    
    init (passwd:String) {
        //m = CryptoMethod.init(cipher: "aes-256-cfb")
        super.init(password: passwd, method: "aes-256-cfb")
        ramdonKey = getPasswordKey(passwd)
    }
    deinit {
        
    }
    //必须
    func getPasswordKey(password:String) ->NSData{
        let hexString = password.md5
        
        if let r =  getSecretKey(hexString){
            return r
        } else {
            return NSData()
        }
        //getSecretKey(hexString)
    }
  
    
    /**
     * 解密
     *
     * @param key
     *          SecretKey
     * @param encrypt_bytes
     *          头部包含16字节IV的加密数据
     *
     * @return
     * 				解密数据
     * 
     */
    
    func decrypt(key:NSData , encrypt_bytes:NSData) ->NSData?{
        if (key.length == 0 || encrypt_bytes.length == 0 ) {
            
            return nil;
            
        }
//        
//        byte[] IV = new byte[IV_SIZE];
//        
//        byte[] part2 = new byte[encrypt_bytes.length - IV_SIZE];
//        
//        System.arraycopy(encrypt_bytes, 0, IV, 0, IV.length);
//        
//        System.arraycopy(encrypt_bytes, IV.length, part2, 0, part2.length);
//        
//        return decrypt(key, part2, IV);
        //Key to Data
        //NSData *key = [keyString dataUsingEncoding:NSUTF8StringEncoding];
        
        // Init cryptor
        
        //Empty IV: initialization vector
        
        
        var used_Length:Int = 0
        if ivBuffer.length  == 0 {
            //有没用没解完的，有先解
            let result = NSMutableData.init()
            if leftdataLength > 0  {
                
                
                if recv_iv == nil {
                    AxLogger.log("recv_iv check fail",level: .Debug)
                }
                
                var length:Int = 0
                var touse:NSData
                if leftdataLength >= encrypt_bytes.length {
                    length = encrypt_bytes.length
                }else {
                    length = leftdataLength
                }
                
                touse = encrypt_bytes.subdataWithRange(NSMakeRange(0,length))
                
                let r0 = decrypt(ramdonKey!, encrypt_bytes:touse , iv: recv_iv!)
                
                
                leftdataLength -= length
                used_Length += length
                
                if leftdataLength == 0 {
                    AxLogger.log("packet decrypt fin clear iv",level: .Debug)
                    recv_iv = nil
                    //recv_ctx?.ctx = nil // reset ctx
                    CCCryptorRelease((recv_ctx?.ctx)!);
                }
                
                
                if used_Length  == encrypt_bytes.length {
                    //正好全部解完
                    return r0
                }else {
                    result.appendData(r0!)
                }
                //let iv:NSData =  encrypt_bytes.subdataWithRange(NSMakeRange(0,m.iv_size))
            }
            
            if lettnoiseLength > 0 {
                let left = encrypt_bytes.length - used_Length
                if left >= lettnoiseLength{
                    
                    used_Length += lettnoiseLength
                    lettnoiseLength -= lettnoiseLength
                }else {
                    used_Length += left
                    lettnoiseLength -= left
                    return result
                }
                
            }
            //是否还有packet 需要解?
            let  left = encrypt_bytes.length - used_Length
            if left > 0 {
                
                let leftdata = encrypt_bytes.subdataWithRange(NSMakeRange(used_Length,encrypt_bytes.length - used_Length))
                
                if let r2 =  descrypt(ramdonKey!, encrypt_bytes_pre: leftdata) {
                    result.appendData(r2)
                }
                return result
            }else {
                //解完了
                return result
            }
            

        }else {
            if leftdataLength > 0 || lettnoiseLength > 0  {
                
                AxLogger.log("ivBuffer error",level:  .Error)
                
            }
            
            ivBuffer.appendData(encrypt_bytes)
            if let r = descrypt(key,encrypt_bytes_pre:ivBuffer){
                return r
            }
            return nil

        }
        

        
        
                //return nil
    }
    func descrypt(key:NSData,encrypt_bytes_pre:NSData) ->NSData?{
        //可能有多个加密包
        //if encrypt_bytes.length < Encrypt.ENCRYPT_SIZE{
        //    ivBuffer.appendData(encrypt_bytes)
        //}
        var used_length = 0
        let total_len = encrypt_bytes_pre.length
        var result = NSMutableData.init()
        while used_length <=  total_len {
            if total_len < Encrypt.ENCRYPT_SIZE {
                ivBuffer.setData(encrypt_bytes_pre)
                return nil
            }
            var tempData = encrypt_bytes_pre.subdataWithRange(NSMakeRange(0, Encrypt.ENCRYPT_SIZE))
            used_length += Encrypt.ENCRYPT_SIZE
            let sizes = getBlockSizes(tempData)
            if sizes.count != 2 {
                AxLogger.log("data size and noise size error",level:  .Error)
            }else {
                leftdataLength = sizes[0]
                lettnoiseLength  = sizes[1]
                AxLogger.log("data size:\(leftdataLength) and noise size: \(lettnoiseLength)",level:  .Debug)
            }
            
            if used_length + m.iv_size < total_len{
                tempData = encrypt_bytes_pre.subdataWithRange(NSMakeRange(used_length,total_len - used_length))
                ivBuffer.setData(tempData)
                return nil
            }else {
                tempData = encrypt_bytes_pre.subdataWithRange(NSMakeRange(used_length,m.iv_size))
                used_length += m.iv_size
            }
            recv_iv = tempData //初始化IV
            
            if used_length + leftdataLength <= total_len {
                //enough 
                tempData = encrypt_bytes_pre.subdataWithRange(NSMakeRange(used_length,leftdataLength))
                used_length += leftdataLength
                leftdataLength = 0
            }else {
                tempData = encrypt_bytes_pre.subdataWithRange(NSMakeRange(used_length,total_len - used_length))
                used_length += total_len - used_length
                leftdataLength -= total_len - used_length
            }
            
            if let t = decrypt(key, encrypt_bytes: tempData, iv: recv_iv!){
                result.appendData(t)
                
            }
            
            if leftdataLength == 0 {
                recv_iv = nil
                //recv_ctx?.ctx = nil // reset ctx
                CCCryptorRelease((recv_ctx?.ctx)!)
                
                let l_len = total_len - used_length
                //left len
                
                if lettnoiseLength <= l_len {
                    lettnoiseLength = 0
                    used_length += lettnoiseLength
                }else {
                    lettnoiseLength -= l_len
                    used_length += l_len
                }
                
            }else {
                // > 0 
                return result
            }
            //var left_length = total_len - used_length
            
        }
        
        
        
       
        
//        let iv:NSData =  encrypt_bytes.subdataWithRange(NSMakeRange(used_Length,m.iv_size))
//        used_Length += m.iv_size
//        let left:NSData = encrypt_bytes.subdataWithRange(NSMakeRange(used_Length,encrypt_bytes.length - used_Length))
//
//        let iv:NSData =  encrypt_bytes.subdataWithRange(NSMakeRange(used_Length,m.iv_size))
//        used_Length += m.iv_size
//        let left:NSData = encrypt_bytes.subdataWithRange(NSMakeRange(used_Length,encrypt_bytes.length - used_Length))
//        let r2 =  decrypt(ramdonKey!, encrypt_bytes:left , iv: iv)
//        result.appendData(r2!)
//        return r2
        return result
        
    }
    /**
     * 解密
     *
     * @param key
     *          SecretKey
     * @param cipher_data
     *          加密数据
     * @param IV
     *          IV
     *
     * @return
     * 				解密数据
     *
     */
    
    func decrypt(key:NSData , encrypt_bytes:NSData,iv:NSData) ->NSData?{
        // Create Cryptor
        
        if recv_ctx == nil {
            recv_ctx = enc_ctx.init(key: key, iv: iv, encrypt: false, method: m)
        }else {
            if recv_ctx!.ctx == nil {
                let  createDecrypt:CCCryptorStatus = CCCryptorCreateWithMode(CCOperation(kCCDecrypt), // operation
                    CCMode(kCCModeCFB), // mode CTR
                    CCAlgorithm(kCCAlgorithmAES128),//kCCAlgorithmAES, // Algorithm
                    CCPadding(ccNoPadding), // padding
                    iv.bytes, // can be NULL, because null is full of zeros
                    key.bytes, // key
                    key.length, // keylength
                    nil, //const void *tweak
                    0, //size_t tweakLength,
                    0, //int numRounds,
                    0, //CCModeOptions options,
                    &recv_ctx!.ctx); //CCCryptorRef *cryptorRef
                if (createDecrypt == CCCryptorStatus(kCCSuccess)){
                    AxLogger.log("create decrypt env error", level: .Error)
                    
                }
            }
        }
        
        
        
        
        let ctx = recv_ctx!.ctx
        
            // Alloc Data Out
            let cipherDataDecrypt:NSMutableData = NSMutableData.init(capacity:encrypt_bytes.length+kCCBlockSizeAES128)!;
            
            //alloc number of bytes written to data Out
            var  outLengthDecrypt:NSInteger = 0
            
            //Update Cryptor
            let updateDecrypt:CCCryptorStatus = CCCryptorUpdate(ctx,
                                                                encrypt_bytes.bytes, //const void *dataIn,
                encrypt_bytes.length,  //size_t dataInLength,
                cipherDataDecrypt.mutableBytes, //void *dataOut,
                cipherDataDecrypt.length, // size_t dataOutAvailable,
                &outLengthDecrypt); // size_t *dataOutMoved)
            
            if (updateDecrypt == CCCryptorStatus(kCCSuccess))
            {
                //Cut Data Out with nedded length
                cipherDataDecrypt.length = outLengthDecrypt;
                
                // Data to String
                //NSString* cipherFinalDecrypt = [[NSString alloc] initWithData:cipherDataDecrypt encoding:NSUTF8StringEncoding];
                
                //Final Cryptor
                let final:CCCryptorStatus = CCCryptorFinal(ctx, //CCCryptorRef cryptorRef,
                    cipherDataDecrypt.mutableBytes, //void *dataOut,
                    cipherDataDecrypt.length, // size_t dataOutAvailable,
                    &outLengthDecrypt); // size_t *dataOutMoved)
                
                if (final != CCCryptorStatus( kCCSuccess))
                {
                    //Release Cryptor
                    //CCCryptorStatus release =
                     //CCCryptorRef cryptorRef
                    AxLogger.log("decrypt error",level: .Debug)
                }
                
                return cipherDataDecrypt ;//cipherFinalDecrypt;
            }
        

        return nil
    }
   
    
    /**
     * 加密
     *
     * @param key
     *          SecretKey
     * @param data
     *          数据
     *
     * @return
     * 				加密数据
     * 
     */
    func encrypt(key:NSData , encrypt_bytes:NSData) ->NSData?{
        var cryptor:CCCryptorRef =  CCCryptorRef()
        //let iv:NSData = NSData();
        //[NSMutableData dataWithLength:kCCBlockSizeAES128]
        let iv:NSData = SSEncrypt.getSecureRandom(m.iv_size)
        let create:CCCryptorStatus = CCCryptorCreateWithMode(CCOperation(kCCEncrypt),
                                                             CCMode(kCCModeCFB),
                                                             CCAlgorithm(kCCAlgorithmAES128),//kCCAlgorithmAES,
                                                            CCPadding(ccNoPadding),
                                                                iv.bytes, // can be NULL, because null is full of zeros
                                                            key.bytes,
                                                            key.length,
                                                            nil,
                                                            0,
                                                            0,
                                                            0,
                                                            &cryptor);
        
        if (create == CCCryptorStatus(kCCSuccess))
        {
            //alloc number of bytes written to data Out
            var  outLength:NSInteger = 0 ;
            // Alloc Data Out
            let cipherData:NSMutableData = NSMutableData.init(length: encrypt_bytes.length)!;
            //Update Cryptor
            let  update:CCCryptorStatus = CCCryptorUpdate(cryptor,
                                                      encrypt_bytes.bytes,
                                                      encrypt_bytes.length,
                                                      cipherData.mutableBytes,
                                                      cipherData.length,
                                                      &outLength);
            if (update == CCCryptorStatus(kCCSuccess))
            {
                //Cut Data Out with nedded length
                cipherData.length = outLength;
                
                //Final Cryptor
                let final:CCCryptorStatus = CCCryptorFinal(cryptor, //CCCryptorRef cryptorRef,
                    cipherData.mutableBytes, //void *dataOut,
                    cipherData.length, // size_t dataOutAvailable,
                    &outLength); // size_t *dataOutMoved)
                
                if (final == CCCryptorStatus(kCCSuccess))
                {
                    //Release Cryptor
                    //CCCryptorStatus release =
                    CCCryptorRelease(cryptor ); //CCCryptorRef cryptorRef
                }
                let d:NSMutableData = NSMutableData()
                d.appendData(iv);
                //NSLog(@"encrypt :%@",cipherData);
                d.appendData(cipherData);
                return d;
                
            }
            
            
            
        }
        
        return nil
    }
    
    /**
     * 加密网络数据
     *
     * @param key
     *          SecretKey
     *
     * @param bytes
     *          原始数据
     *
     * @return
     * 				[加密数据+噪音数据]长度值的加密数据 + [加密数据 + 噪音数据]
     *
     */
    func encryptNet(key:NSData,encrypt_bytes: NSData) -> NSData? {
        
        let iv = Encrypt.getSecureRandom(m.iv_size)
        
        send_ctx = enc_ctx.init(key: ramdonKey!, iv: iv, encrypt: true, method: m)
        let create:CCCryptorStatus = CCCryptorCreateWithMode(CCOperation(kCCEncrypt),
                                                             CCMode(kCCModeCFB),
                                                             CCAlgorithm(kCCAlgorithmAES128),//kCCAlgorithmAES,
            CCPadding(ccNoPadding),
            iv.bytes, // can be NULL, because null is full of zeros
            ramdonKey!.bytes,
            m.key_size,
            nil,
            0,
            0,
            0,
            &send_ctx!.ctx);
        
        var cipher_bytes:NSData?
        if (create == CCCryptorStatus(kCCSuccess))
        {
            //alloc number of bytes written to data Out
            var  outLength:NSInteger = 0 ;
            // Alloc Data Out
            let cipherData:NSMutableData = NSMutableData.init(length: encrypt_bytes.length)!;
            //Update Cryptor
            let  update:CCCryptorStatus = CCCryptorUpdate(send_ctx!.ctx,
                                                          encrypt_bytes.bytes,
                                                          encrypt_bytes.length,
                                                          cipherData.mutableBytes,
                                                          cipherData.length,
                                                          &outLength);
            if (update == CCCryptorStatus(kCCSuccess))
            {
                //Cut Data Out with nedded length
                cipherData.length = outLength;
                
                //Final Cryptor
                let final:CCCryptorStatus = CCCryptorFinal(send_ctx!.ctx, //CCCryptorRef cryptorRef,
                    cipherData.mutableBytes, //void *dataOut,
                    cipherData.length, // size_t dataOutAvailable,
                    &outLength); // size_t *dataOutMoved)
                
                if (final == CCCryptorStatus(kCCSuccess))
                {
                    //Release Cryptor
                    //CCCryptorStatus release =
                    CCCryptorRelease(send_ctx!.ctx ); //CCCryptorRef cryptorRef
                }
//                let d:NSMutableData = NSMutableData()
//                d.appendData(iv);
//                //NSLog(@"encrypt :%@",cipherData);
//                d.appendData(cipherData);
//                cipher_bytes =  d;
                cipher_bytes = cipherData
                
            }

        
        
        }
        if let d = cipher_bytes {
            var noise_bytes:NSData
            if d.length < Encrypt.NOISE_MAX / 2{
                noise_bytes = Encrypt.getSecureRandom(64) //Encrypt.NOISE_MAX
            }else {
                noise_bytes = NSData()
            }
            
            let size_buffer = getBlockSizeBytes(Encrypt.IV_SIZE + cipher_bytes!.length,noise_size: noise_bytes.length)
            if let size_bytes = encrypt(key, encrypt_bytes: size_buffer){
                let r_length = size_bytes.length + m.iv_size + cipher_bytes!.length + noise_bytes.length
                let result = NSMutableData.init(data: size_bytes)
                result.appendData(iv)
                result.appendData(d)
                
                if (noise_bytes.length > 0) { // 是否加噪音数据
                    result.appendData(noise_bytes)
                }
                if r_length != result {
                    fatalError()
                }
                return result
                
            }
            
        }
        
        return nil
    }
    /**
     * 还原块长度值
     *
     * @param bytes
     *          块长度字节数组
     *
     * @return
     * 				块长度值
     * 
     */
    
    func getBlockSize(bytes:NSData) ->Int{
        if let s =  String.init(data: bytes, encoding: NSUTF8StringEncoding){
            if let x = Int(s){
                return x
            }
        }
        return 0
    }
    
    func getBlockSizes(bytes:NSData) ->[Int]{
        if let s =  String.init(data: bytes, encoding: NSUTF8StringEncoding){
            let x = s.componentsSeparatedByString(",")
            if x.count == 2{
                var r:[Int] = []
                r.append(Int(x.first!)!)
                r.append(Int(x.last!)!)
            }
        }
        return [0]
    }
    /**
     * 块长度值转换为字节数组
     *
     * @param size
     *          加密后的数据块总长度值
     *
     * @param noise_size
     *          加密前的噪音数据块长度值
     *
     * @return
     * 				块长度值字节数组
     */
    func getBlockSizeBytes(data_size:Int,noise_size:Int) ->NSData{
        let s = String.init(format: "%08d,%05d", data_size, noise_size)
        return s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
    func getBlockSizeBytes(i:Int32) ->NSData{
        let s = String.init(format: "%08d", i)
        return s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
    
    func getSecretKey(key:String) ->NSData? {
        if let data = NSData.init(base64EncodedString: key, options:.IgnoreUnknownCharacters){
            return data
        }
        return nil
    }
    /**
     * 从字节数组还原块长度值
     *
     * @param bytes
     *          长度值字节数组，格式 %08d,%05d
     * @return int[2]
     */
    
//    func getSecureRandom(bytesCount:Int) ->NSData {
//        // Swift
//        //import Security
//        
//        //let bytesCount = 4 // number of bytes
//        //var randomNum: UInt32 = 0 // variable for random unsigned 32 bit integer
//        var randomBytes = [UInt8](count: bytesCount, repeatedValue: 0) // array to hold randoms bytes
//        
//        // Gen random bytes
//        SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
//        
//        // Turn bytes into data and pass data bytes into int
//        return NSData(bytes: randomBytes, length: bytesCount) //getBytes(&randomNum, length: bytesCount)
//    }
/*
 // Swift
 import Security
 
 let bytesCount = 32 // number of bytes
 var randomNum = "" // hexadecimal version of randomBytes
 var randomBytes = [UInt8](count: bytesCount, repeatedValue: 0) // array to hold randoms bytes
 
 // Gen random bytes
 SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
 
 // Turn randomBytes into array of hexadecimal strings
 // Join array of strings into single string
 randomNum = randomBytes.map({String(format: "%02hhx", $0)}).joinWithSeparator("")
 */
        
//    func  getStringKey(secretKey:NSData) ->String?{
//    
//        return secretKey.base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
//        //Base64.encodeBase64String
//    
//    }

     func  isPassword(password:String) ->Bool {
    
        //if !password.matches("^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=\\S+$).{8,}$")) {
        //pass check
        return true;
    }
    
}
