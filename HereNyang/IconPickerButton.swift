//
//  IconPickerButton.swift
//  HereNyang
//
//  현재 아이콘을 미리보기로 보여주다가, 누르면 SF Symbol/이미지 두 탭으로 나뉜
//  선택 팝오버를 띄운다.
//

import SwiftUI

struct IconPickerButton: View {
    let selectedIcon: PlaceIcon
    // 팝오버를 띄우기 직전에 호출. 이름 입력칸에 포커스가 남아있으면 팝오버가 뜨면서
    // 키보드만 내려가고 @FocusState는 그대로라 이후 키보드가 안 닫히는 상태가 되므로,
    // 여기서 포커스를 먼저 정리한다.
    var onOpen: (() -> Void)? = nil
    let onSelect: (PlaceIcon) -> Void

    @State private var showingPicker = false

    var body: some View {
        Button {
            onOpen?()
            showingPicker = true
        } label: {
            IconThumbnail(icon: selectedIcon, size: 32)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPicker) {
            IconPickerSheet(selectedIcon: selectedIcon) { icon in
                onSelect(icon)
                showingPicker = false
            }
            .frame(minWidth: 280, idealHeight: 320)
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct IconThumbnail: View {
    let icon: PlaceIcon
    let size: CGFloat

    var body: some View {
        switch icon.kind {
        case .symbol:
            Image(systemName: icon.name)
                .font(.system(size: size * 0.55))
                .frame(width: size, height: size)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
        case .image:
            Image(icon.name)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}

private struct IconPickerSheet: View {
    let selectedIcon: PlaceIcon
    let onSelect: (PlaceIcon) -> Void

    @State private var tab: PlaceIconKind = .symbol

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .symbol:
                    SymbolGrid(selectedIcon: selectedIcon, onSelect: onSelect)
                case .image:
                    ImageGrid(selectedIcon: selectedIcon, onSelect: onSelect)
                }
            }
            .frame(maxHeight: .infinity)

            Picker("탭", selection: $tab) {
                Label("아이콘", systemImage: "square.grid.3x3.fill").tag(PlaceIconKind.symbol)
                Label("이미지", systemImage: "photo.fill").tag(PlaceIconKind.image)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()
        }
    }
}

private struct SymbolGrid: View {
    let selectedIcon: PlaceIcon
    let onSelect: (PlaceIcon) -> Void

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(PlaceIconCatalog.symbolNames, id: \.self) { name in
                    let isSelected = selectedIcon.kind == .symbol && selectedIcon.name == name
                    Button {
                        onSelect(PlaceIcon(name: name, kind: .symbol))
                    } label: {
                        Image(systemName: name)
                            .font(.system(size: 17))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
                            )
                            .overlay(
                                Circle().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// 지금은 집/회사에도 쓰는 고양이 일러스트 2종뿐. 나중에 구매한 아이콘은
// PlaceImageCatalog.entries에 추가하기만 하면 이 그리드에 자동으로 반영된다.
private struct ImageGrid: View {
    let selectedIcon: PlaceIcon
    let onSelect: (PlaceIcon) -> Void

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(PlaceImageCatalog.entries) { entry in
                    let isSelected = selectedIcon.kind == .image && selectedIcon.name == entry.assetName
                    Button {
                        onSelect(PlaceIcon(name: entry.assetName, kind: .image))
                    } label: {
                        VStack(spacing: 4) {
                            Image(entry.assetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            Text(entry.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}
