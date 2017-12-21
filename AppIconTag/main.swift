//
//  main.swift
//  AppIconTag
//
//  Created by Abelchen on 2017/12/21.
//  Copyright © 2017年 Tencent. All rights reserved.
//
/*
 * AppIconTag [-fsctgh] SourcFile
 * -s  : imageSize
 * -c  : color
 * -bc : backgroundColor
 * -t  : text
 * -f  : fontSize
 * -g  : gravity
 * -h  : height
 */

import AppKit

struct AppIconInfo {
    enum Gravity : String {
        case Top = "Top"
        case Bottom = "Bottom"
    }
    
    var path: String = ""
    var imageSize: Int = 0
    var fontSize: Int = 24
    var color: NSColor = .white
    var backgroundColor: NSColor = .white
    var text: String = ""
    var gravity: Gravity = .Bottom
    var height: Int = 30
}

func hexStringToInt(_ hex: String) -> Int? {
    var str = hex.uppercased()
    if str.hasPrefix("0X") {
        str = String(str.suffix(str.count - 2))
    }
    var value = 0;
    for c in str {
        value <<= 4
        switch c {
        case "0"..."9":
            value += Int(c.unicodeScalars.first!.value - "0".unicodeScalars.first!.value)
        case "A"..."F":
            value += Int(c.unicodeScalars.first!.value - "A".unicodeScalars.first!.value) + 10
        default:
            return nil
        }
    }
    return value
}

func parseColor(_ hex: String) -> NSColor {
    var colorValue = 0xFFFFFFFF
    if let hex = hexStringToInt(hex) {
        colorValue = hex
    }
    let a = CGFloat(colorValue & 0xFF) / 255.0
    colorValue = colorValue >> 8
    let b = CGFloat(colorValue & 0xFF) / 255.0
    colorValue = colorValue >> 8
    let g = CGFloat(colorValue & 0xFF) / 255.0
    colorValue = colorValue >> 8
    let r = CGFloat(colorValue & 0xFF) / 255.0
    colorValue = colorValue >> 8
    return NSColor(red: r, green: g, blue: b, alpha: a)
}

func parseArguments() -> AppIconInfo? {
    let argc = CommandLine.argc
    let argvs = CommandLine.arguments
    var pos = 0
    
    func getArg() -> String? {
        guard pos < argc else {
            return nil
        }
        let arg = argvs[pos]
        pos += 1
        return arg
    }
    
    _ = getArg()
    
    var info = AppIconInfo()
    
    while true {
        if let arg = getArg() {
            if arg.hasPrefix("-") {
                guard let value = getArg() else {
                    return nil
                }
                switch arg {
                case "-f":
                    info.fontSize = Int(value) ?? 24
                case "-s":
                    info.imageSize = Int(value) ?? 0
                case "-c":
                    info.color = parseColor(value)
                case "-bc":
                    info.backgroundColor = parseColor(value)
                case "-t":
                    info.text = value
                case "-g":
                    info.gravity = AppIconInfo.Gravity.init(rawValue: value) ?? .Bottom
                case "-h":
                    info.height = Int(value) ?? 24
                default:
                    return nil
                }
            }else if info.path == ""{
                info.path = arg
            }else{
                return nil
            }
        }else{
            break
        }
    }
    if info.path == "" {
        return nil
    }
    return info
}

func savePNG(image:NSImage, path:String) {
    let imageRep = unscaledBitmapImageRep(image)
    guard let data = imageRep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        preconditionFailure()
    }
    do{
        try data.write(to: URL(fileURLWithPath: path))
    }catch{}
}

func unscaledBitmapImageRep(_ image: NSImage) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(image.size.width),
        pixelsHigh: Int(image.size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
        ) else {
            preconditionFailure()
    }
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    
    return rep
}

func draw(icon:NSImage, info:AppIconInfo) -> NSImage? {
    if info.imageSize <= 0 {
        return nil
    }
    
    let image = NSImage(size: NSSize(width: info.imageSize, height: info.imageSize))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    icon.draw(in: NSRect(origin: CGPoint.zero, size: image.size))
    
    var textRect = NSRect(x: 0, y: 0, width: info.imageSize, height: info.height)
    if info.gravity == .Top {
        textRect.origin.y = CGFloat(info.imageSize - info.height)
    }
    
    info.backgroundColor.set()
    ctx.fill(textRect)
    
    info.color.set()
    if info.text != "" {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let str = NSAttributedString(string: info.text, attributes: [.font:NSFont(name:"Helvetica", size:CGFloat(info.fontSize))!, .foregroundColor:info.color, .paragraphStyle:style])
        let realRect = str.boundingRect(with: textRect.size, options: .usesFontLeading)
        let textHeight = realRect.size.height
        textRect.origin.y -= (textRect.size.height - textHeight) / 2
        str.draw(in: textRect)
    }
    
    image.unlockFocus()
    return image
}

guard var info = parseArguments() else {
    print("AppIconTag: 解析参数错误")
    exit(0)
}

guard let image = NSImage(contentsOfFile: info.path) else {
    print("AppIconTag: 图标打开失败")
    exit(0)
}

if info.imageSize == 0 {
    info.imageSize = Int(image.size.width)
}

if let outImage = draw(icon: image, info: info) {
    savePNG(image: outImage, path: info.path)
}else{
    print("AppIconTag: 图标绘制失败")
}
