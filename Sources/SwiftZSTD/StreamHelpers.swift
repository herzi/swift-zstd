//
//  StreamHelpers.swift
//  swift-zstd
//
//  Created by Sven Herzberg on 2023-08-13.
//

import Foundation

import zstdlib

final class Compression {
    
    private var cStream: OpaquePointer!

    var inProgress: Bool
    
    private var outputData: Data
    
    public init () {
        outputData = Data(count: ZSTD_CStreamOutSize())
        cStream = ZSTD_createCStream()
        inProgress = false
    }
    
    deinit {
        ZSTD_freeCStream(cStream)
    }

    func start(_ compressionLevel: Int32) -> Bool {
        guard !inProgress else {
            return false
        }
        inProgress = true
        ZSTD_initCStream(cStream, compressionLevel)
        return true
    }

    func processData(_ dataIn: Data, andFinalize flag: Bool, withErrorCode errorCode: inout Int) -> Data? {
        outputData.withUnsafeMutableBytes { outputBuffer in
            dataIn.withUnsafeBytes { buffer in
                var inBuffer = ZSTD_inBuffer(src: buffer.baseAddress, size: buffer.count, pos: buffer.startIndex)
                var outBuffer = ZSTD_outBuffer(dst: outputBuffer.baseAddress, size: outputBuffer.count, pos: outputBuffer.startIndex)
                
                errorCode = 0
                
                var result = Data()
                
                repeat {
                    var remainingBytes = 0
                    let rc = ZSTD_compressStream(cStream, &outBuffer, &inBuffer)
                    if ZSTD_isError(rc) != 0 {
                        errorCode = rc
                        return nil
                    }
                    let flusher = !flag || inBuffer.pos < inBuffer.size ? ZSTD_flushStream(_:_:) : ZSTD_endStream(_:_:)
                    repeat {
                        remainingBytes = flusher(cStream, &outBuffer)
                        if ZSTD_isError(remainingBytes) != 0 {
                            errorCode = remainingBytes
                            return nil
                        }
                        result.append(Data(outputBuffer)[..<outBuffer.pos])
                        outBuffer.pos = 0
                    } while remainingBytes > 0
                } while inBuffer.pos < inBuffer.size
                            
                if flag {
                    inProgress = false
                }
                
                return result
            }
        }
    }
}

final class Decompression {
    
    private var dStream: OpaquePointer!

    var inProgress: Bool
    
    private var outputData: Data

    public init () {
        let outputSize = ZSTD_DStreamOutSize()
        outputData = Data(count: outputSize)
        dStream = ZSTD_createDStream()
        inProgress = false
    }
    
    deinit {
        ZSTD_freeDStream(dStream)
    }

    func start() -> Bool {
        guard !inProgress else {
            return false
        }
        ZSTD_initDStream(dStream)
        inProgress = true
        return true
    }

    func processData(_ dataIn: Data, withErrorCode errorCode: inout Int) -> Data? {
        outputData.withUnsafeMutableBytes { outputBuffer in
            dataIn.withUnsafeBytes { inputBuffer in
                var inBuffer = ZSTD_inBuffer(src: inputBuffer.baseAddress, size: inputBuffer.count, pos: inputBuffer.startIndex)
                var outBuffer = ZSTD_outBuffer(dst: outputBuffer.baseAddress, size: outputBuffer.count, pos: outputBuffer.startIndex)
                errorCode = 0
                
                var result = Data()
                repeat {
                    let rc = ZSTD_decompressStream(dStream, &outBuffer, &inBuffer)
                    if ZSTD_isError(rc) != 0 {
                        errorCode = rc
                        return nil
                    }
                    result.append(Data(outputBuffer)[..<outBuffer.pos])
                    if rc == 0 {
                        inProgress = false
                        break
                    }
                    outBuffer.pos = 0
                } while inBuffer.pos < inBuffer.size
                
                return result
            }
        }
    }
}
