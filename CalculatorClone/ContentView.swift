//
//  ContentView.swift
//  CalculatorClone
//
//  Created by Артемий Андреев  on 15.03.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var display: String = "0"
    @State private var lastExpression: String = ""
    @State private var didJustCalculate: Bool = false
    
    let buttonSize: CGFloat = 70
    let buttonSpacing: CGFloat = 12
    var totalRowWidth: CGFloat {
        (4 * buttonSize) + (3 * buttonSpacing)
    }
    
    let buttonRows: [[String]] = [
        ["AC", "+/-", "%", "÷"],
        ["7",  "8",  "9",  "×"],
        ["4",  "5",  "6",  "-"],
        ["1",  "2",  "3",  "+"],
        ["0span", ".", "=", ""]
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: buttonSpacing) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(lastExpression)
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .padding(.trailing, 5)
                        
                        Text(display)
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.trailing, 5)
                    }
                }
                .padding(.horizontal)
                
                ForEach(buttonRows, id: \.self) { row in
                    HStack(spacing: buttonSpacing) {
                        ForEach(row, id: \.self) { label in
                            if label.isEmpty {
                                Color.clear
                                    .frame(width: buttonSize, height: buttonSize)
                            }
                            else if label == "0span" {
                                Button {
                                    buttonPressed("0")
                                } label: {
                                    Text("0")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: (buttonSize * 2) + buttonSpacing,
                                               height: buttonSize)
                                        .background(Color(white: 0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            else {
                                Button {
                                    buttonPressed(label)
                                } label: {
                                    Text(label)
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: buttonSize, height: buttonSize)
                                        .background(getButtonColor(for: label))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .frame(width: totalRowWidth, alignment: .leading)
                }
            }
            .padding(.bottom, 20)
        }
    }
}


extension ContentView {
    func getButtonColor(for label: String) -> Color {
        if ["÷", "×", "-", "+", "="].contains(label) {
            return .orange
        } else if ["AC", "+/-", "%"].contains(label) {
            return .gray
        } else {
            return Color(white: 0.2)
        }
    }
    
    func buttonPressed(_ label: String) {
        if didJustCalculate && label != "=" {
            clearAll()
        }
        didJustCalculate = false
        
        switch label {
        case "0"..."9":
            handleNumber(label)
        case ".":
            handleDecimal()
        case "AC":
            clearAll()
        case "+/-":
            toggleSignOfLastNumber()
        case "%":
            applyPercentToLastNumber()
        case "÷", "×", "-", "+":
            handleOperator(label)
        case "=":
            calculateFullExpression()
        default:
            break
        }
    }
    
    func clearAll() {
        display = "0"
        lastExpression = ""
    }
        
    func handleNumber(_ num: String) {
        if display == "0" || display == "Ошибка" {
            display = num
        } else {
            display.append(num)
        }
    }
    
    func handleDecimal() {
        if display == "Ошибка" {
            display = "0."
            return
        }
        if !parseLastNumber(from: display).contains(".") {
            display.append(".")
        }
    }
        
    func toggleSignOfLastNumber() {
        let range = getLastNumberRange(in: display)
        guard !range.isEmpty else { return }
        let valStr = String(display[range])
        if let val = Double(valStr) {
            display.replaceSubrange(range, with: formatValue(-val))
        }
    }
    
    func applyPercentToLastNumber() {
        let range = getLastNumberRange(in: display)
        guard !range.isEmpty else { return }
        let valStr = String(display[range])
        if let val = Double(valStr) {
            display.replaceSubrange(range, with: formatValue(val / 100))
        }
    }
    
    func handleOperator(_ op: String) {
        if display == "Ошибка" {
            display = "0"
        }
        if endsWithOperator(display) {
            replaceLastOperator(with: op)
        } else {
            if display == "0" {
                display = "0 \(op) "
            } else {
                display.append(" \(op) ")
            }
        }
    }
    
    func calculateFullExpression() {
        lastExpression = display
        
        if let val = evaluateExpressionLeftToRight(display) {
            display = formatValue(val)
        } else {
            display = "Ошибка"
        }
        didJustCalculate = true
    }
    
    func evaluateExpressionLeftToRight(_ expr: String) -> Double? {
        let tokens = expr.split(separator: " ").map { String($0) }
        guard !tokens.isEmpty else { return nil }
        guard var currentValue = Double(tokens[0]) else { return nil }
        
        var i = 1
        while i < tokens.count - 1 {
            let op = tokens[i]
            guard let nextValue = Double(tokens[i+1]) else { return nil }
            currentValue = applyOperator(op, to: currentValue, and: nextValue)
            i += 2
        }
        return currentValue
    }
    
    func applyOperator(_ op: String, to left: Double, and right: Double) -> Double {
        switch op {
        case "+": return left + right
        case "-": return left - right
        case "×": return left * right
        case "÷":
            if right == 0 { return .nan }
            return left / right
        default:
            return left
        }
    }
    
    func formatValue(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "Ошибка" }
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 6
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    func endsWithOperator(_ str: String) -> Bool {
        let t = str.trimmingCharacters(in: .whitespaces)
        return t.hasSuffix("+") || t.hasSuffix("-") || t.hasSuffix("×") || t.hasSuffix("÷")
    }
    
    func replaceLastOperator(with newOp: String) {
        var parts = display.split(separator: " ").map { String($0) }
        if let i = parts.lastIndex(where: { ["+","-","×","÷"].contains($0) }) {
            parts[i] = newOp
        }
        display = parts.joined(separator: " ")
        display.append(" ")
    }
    
    func getLastNumberRange(in s: String) -> Range<String.Index> {
        let tokens = s.split(separator: " ")
        guard let last = tokens.last, Double(last) != nil else {
            return Range(uncheckedBounds: (s.endIndex, s.endIndex))
        }
        if let r = s.range(of: last, options: .backwards) {
            return r
        }
        return Range(uncheckedBounds: (s.endIndex, s.endIndex))
    }
    
    func parseLastNumber(from s: String) -> String {
        let r = getLastNumberRange(in: s)
        return String(s[r])
    }
}
