import AppKit

class ConfigurationWindow: NSWindowController {
    private let stationManager: StationManager
    private var tableView: NSTableView!
    private var stations: [Station] = []
    private var editorWindow: StationEditorWindow?  // Keep reference to prevent deallocation

    var onStationsChanged: (() -> Void)?

    init(stationManager: StationManager) {
        self.stationManager = stationManager
        self.stations = stationManager.stations

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "zelerK - Stations"
        window.center()
        window.minSize = NSSize(width: 400, height: 300)

        super.init(window: window)

        setupUI()
        reloadStations()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Create scroll view with table
        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        tableView.allowsMultipleSelection = false
        tableView.doubleAction = #selector(editSelectedStation)
        tableView.target = self

        // Add columns
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Name"
        nameColumn.width = 150
        nameColumn.minWidth = 100
        tableView.addTableColumn(nameColumn)

        let urlColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("url"))
        urlColumn.title = "Stream URL"
        urlColumn.width = 280
        urlColumn.minWidth = 150
        tableView.addTableColumn(urlColumn)

        scrollView.documentView = tableView

        contentView.addSubview(scrollView)

        // Create button bar
        let buttonBar = NSView()
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonBar)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addStation))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bezelStyle = .rounded
        buttonBar.addSubview(addButton)

        let editButton = NSButton(title: "Edit", target: self, action: #selector(editSelectedStation))
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.bezelStyle = .rounded
        buttonBar.addSubview(editButton)

        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedStation))
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.bezelStyle = .rounded
        buttonBar.addSubview(removeButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            buttonBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            buttonBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            buttonBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            buttonBar.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: buttonBar.topAnchor, constant: -10),

            addButton.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor),
            addButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),

            editButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 10),
            editButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),

            removeButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 10),
            removeButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
        ])
    }

    private func reloadStations() {
        stations = stationManager.stations
        tableView.reloadData()
    }

    @objc private func addStation() {
        showStationEditor(station: nil)
    }

    @objc private func editSelectedStation() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < stations.count else { return }
        showStationEditor(station: stations[selectedRow])
    }

    @objc private func removeSelectedStation() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < stations.count else { return }

        let alert = NSAlert()
        alert.messageText = "Remove Station"
        alert.informativeText = "Are you sure you want to remove \"\(stations[selectedRow].name)\"?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            stationManager.deleteStation(at: selectedRow)
            reloadStations()
            onStationsChanged?()
        }
    }

    private func showStationEditor(station: Station?) {
        editorWindow = StationEditorWindow(station: station) { [weak self] updatedStation in
            guard let self = self else { return }

            if let station = station {
                // Update existing
                let modified = Station(id: station.id, name: updatedStation.name, streamURL: updatedStation.streamURL, apiURL: updatedStation.apiURL)
                self.stationManager.updateStation(modified)
            } else {
                // Add new
                self.stationManager.addStation(updatedStation)
            }

            self.reloadStations()
            self.onStationsChanged?()
        }
        editorWindow?.onClose = { [weak self] in
            self?.editorWindow = nil
        }
        editorWindow?.showWindow(nil)
        editorWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension ConfigurationWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stations.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < stations.count else { return nil }
        let station = stations[row]

        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("cell")
        var cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView?.addSubview(textField)
            cellView?.textField = textField

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -5),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        if tableColumn?.identifier.rawValue == "name" {
            cellView?.textField?.stringValue = station.name
        } else if tableColumn?.identifier.rawValue == "url" {
            cellView?.textField?.stringValue = station.streamURL.absoluteString
        }

        return cellView
    }
}

// MARK: - Station Editor Window

class StationEditorWindow: NSWindowController, NSWindowDelegate {
    private var nameField: NSTextField!
    private var streamURLField: NSTextField!
    private var apiURLField: NSTextField!
    private let existingStation: Station?
    private let onSave: (Station) -> Void
    var onClose: (() -> Void)?

    init(station: Station?, onSave: @escaping (Station) -> Void) {
        self.existingStation = station
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = station == nil ? "Add Station" : "Edit Station"
        window.center()

        super.init(window: window)

        window.delegate = self

        setupUI()

        if let station = station {
            nameField.stringValue = station.name
            streamURLField.stringValue = station.streamURL.absoluteString
            apiURLField.stringValue = station.apiURL?.absoluteString ?? ""
        }
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.spacing = 15
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        contentView.addSubview(stackView)

        // Name field
        let nameRow = createFieldRow(label: "Name:", placeholder: "Station Name")
        nameField = nameRow.1
        stackView.addArrangedSubview(nameRow.0)

        // Stream URL field
        let streamRow = createFieldRow(label: "Stream URL:", placeholder: "https://example.com/stream.mp3")
        streamURLField = streamRow.1
        stackView.addArrangedSubview(streamRow.0)

        // API URL field
        let apiRow = createFieldRow(label: "API URL:", placeholder: "https://example.com/api/nowplaying/1 (optional)")
        apiURLField = apiRow.1
        stackView.addArrangedSubview(apiRow.0)

        // Buttons
        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"  // Escape key
        buttonRow.addArrangedSubview(cancelButton)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        buttonRow.addArrangedSubview(spacer)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"  // Enter key
        buttonRow.addArrangedSubview(saveButton)

        stackView.addArrangedSubview(buttonRow)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    private func createFieldRow(label: String, placeholder: String) -> (NSView, NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 10

        let labelView = NSTextField(labelWithString: label)
        labelView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        labelView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        row.addArrangedSubview(labelView)

        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(textField)

        return (row, textField)
    }

    @objc private func cancel() {
        close()
    }

    @objc private func save() {
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let streamURLString = streamURLField.stringValue.trimmingCharacters(in: .whitespaces)
        let apiURLString = apiURLField.stringValue.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            showError("Please enter a station name.")
            return
        }

        guard let streamURL = URL(string: streamURLString), streamURL.scheme != nil else {
            showError("Please enter a valid stream URL.")
            return
        }

        var apiURL: URL? = nil
        if !apiURLString.isEmpty {
            apiURL = URL(string: apiURLString)
            if apiURL?.scheme == nil {
                showError("Please enter a valid API URL or leave it empty.")
                return
            }
        }

        let station = Station(
            id: existingStation?.id ?? UUID(),
            name: name,
            streamURL: streamURL,
            apiURL: apiURL
        )

        onSave(station)
        close()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Invalid Input"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
