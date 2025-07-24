// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public final class PieChartView: UIView {
    private let segmentColors: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemBlue,
        .systemGreen,
        .systemYellow,
        .systemPink
    ]
    
    public var entities: [PieChartEntity] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !entities.isEmpty else { return }
        
        let total = entities.reduce(Decimal(0)) { $0 + $1.value }
        guard total > 0 else { return }
        let sections: [PieChartEntity]
        if entities.count <= 6 {
            sections = entities
        } else {
            let firstFive = entities.prefix(5)
            let rest = entities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
            sections = Array(firstFive) + [PieChartEntity(value: rest, label: "Остальные")]
        }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let lineWidth: CGFloat = min(rect.width, rect.height) * 0.1
        let radius = min(rect.width, rect.height) / 2 - lineWidth/2 - 4
        let startOffset = -CGFloat.pi / 2
        let totalDouble = (total as NSDecimalNumber).doubleValue
        
        var startAngle = startOffset
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.butt)
        
        for (idx, sec) in sections.enumerated() {
            let frac = (sec.value as NSDecimalNumber).doubleValue / totalDouble
            let sweep = CGFloat(frac * 2 * .pi)
            let endAngle = startAngle + sweep
            
            ctx.setStrokeColor(segmentColors[idx % segmentColors.count].cgColor)
            ctx.addArc(center: center,
                       radius: radius,
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false)
            ctx.strokePath()
            startAngle = endAngle
        }
        
        let legendFont = UIFont.systemFont(ofSize: 14)
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        
        let legend = NSMutableAttributedString()
        let pctFactor = 100.0 / totalDouble * totalDouble
        
        for (idx, sec) in sections.enumerated() {
            let bullet = "● "
            let bulletAttr: [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: segmentColors[idx % segmentColors.count],
                .paragraphStyle: pstyle
            ]
            legend.append(NSAttributedString(string: bullet, attributes: bulletAttr))
            
            let perc = (sec.value as NSDecimalNumber).doubleValue / totalDouble * 100
            let label = String(format: "%.0f%% %@", perc, sec.label)
            let textAttr: [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: pstyle
            ]
            legend.append(NSAttributedString(string: label, attributes: textAttr))
            
            if idx < sections.count - 1 {
                legend.append(NSAttributedString(string: "\n", attributes: textAttr))
            }
        }
        
        let maxW = radius * 1.5
        let legendSize = legend.boundingRect(
            with: CGSize(width: maxW, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        let legendRect = CGRect(
            x: center.x - legendSize.width/2,
            y: center.y - legendSize.height/2,
            width: legendSize.width,
            height: legendSize.height
        )
        legend.draw(in: legendRect)
    }
    
    public func animateTransition(to newEntities: [PieChartEntity], duration: TimeInterval = 1.0) {
        layer.transform = CATransform3DIdentity
        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: [.calculationModeLinear],
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    self.layer.transform = CATransform3DMakeRotation(.pi * 2, 0, 0, 1)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.alpha = 0
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0) {
                    self.entities = newEntities
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.alpha = 1
                }
            },
            completion: { _ in
                self.layer.transform = CATransform3DIdentity
            }
        )
    }

}
