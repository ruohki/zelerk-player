import AppKit

class ScrollingTextView: NSView {
    private var text: String = ""
    private var textLayer: CATextLayer?
    private var scrollOffset: CGFloat = 0
    private var displayLink: CVDisplayLink?
    private var isScrolling = false

    var scrollSpeed: CGFloat = 30.0  // Pixels per second
    var pauseDuration: TimeInterval = 2.0  // Pause at start/end
    var textColor: NSColor = .labelColor
    var font: NSFont = .systemFont(ofSize: 12)

    private var lastTimestamp: CFTimeInterval = 0
    private var pauseStartTime: CFTimeInterval = 0
    private var isPaused = false
    private var textWidth: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        layer?.masksToBounds = true

        textLayer = CATextLayer()
        textLayer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer?.alignmentMode = .left
        textLayer?.truncationMode = .none
        layer?.addSublayer(textLayer!)
    }

    func setText(_ newText: String) {
        text = newText
        updateTextLayer()
        checkIfScrollingNeeded()
    }

    private func updateTextLayer() {
        guard let textLayer = textLayer else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        textLayer.string = attributedString
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = textColor.cgColor

        // Calculate text width
        let textSize = attributedString.size()
        textWidth = textSize.width
        textLayer.frame = CGRect(x: 0, y: 0, width: textWidth, height: bounds.height)
    }

    private func checkIfScrollingNeeded() {
        let needsScrolling = textWidth > bounds.width

        if needsScrolling && !isScrolling {
            startScrolling()
        } else if !needsScrolling && isScrolling {
            stopScrolling()
            scrollOffset = 0
            updateTextPosition()
        }
    }

    private func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        scrollOffset = 0
        isPaused = true
        pauseStartTime = CACurrentMediaTime()

        // Use timer-based animation for simplicity
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isScrolling else {
                timer.invalidate()
                return
            }
            self.updateAnimation()
        }
    }

    private func stopScrolling() {
        isScrolling = false
    }

    private func updateAnimation() {
        let currentTime = CACurrentMediaTime()

        if isPaused {
            if currentTime - pauseStartTime >= pauseDuration {
                isPaused = false
                lastTimestamp = currentTime
            }
            return
        }

        let deltaTime = currentTime - lastTimestamp
        lastTimestamp = currentTime

        scrollOffset += CGFloat(deltaTime) * scrollSpeed

        let maxScroll = textWidth - bounds.width + 20  // Extra padding

        if scrollOffset >= maxScroll {
            // Reached end, pause and reset
            scrollOffset = 0
            isPaused = true
            pauseStartTime = currentTime
        }

        updateTextPosition()
    }

    private func updateTextPosition() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        textLayer?.frame.origin.x = -scrollOffset
        CATransaction.commit()
    }

    override func layout() {
        super.layout()
        textLayer?.frame.size.height = bounds.height
        checkIfScrollingNeeded()
    }

    deinit {
        stopScrolling()
    }
}
