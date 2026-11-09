/*
 * SPDX-FileCopyrightText: 2026 Krita Mobile project contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef KIS_MOBILE_BRIDGE_H
#define KIS_MOBILE_BRIDGE_H

#include <QObject>
#include <QString>
#include <QVariantList>

#include "kritaui_export.h"

class KisMainWindow;

/**
 * Thin QObject adapter for invoking existing Krita window actions from QML.
 * It does not implement document, layer, brush, or painting behavior.
 */
class KRITAUI_EXPORT KisMobileBridge : public QObject
{
    Q_OBJECT

public:
    explicit KisMobileBridge(KisMainWindow *mainWindow);

    Q_INVOKABLE bool triggerAction(const QString &actionId) const;
    Q_INVOKABLE bool isActionEnabled(const QString &actionId) const;
    Q_INVOKABLE bool hasActiveDocument() const;
    Q_INVOKABLE qreal brushSize() const;
    Q_INVOKABLE qreal brushOpacity() const;
    Q_INVOKABLE bool setBrushSize(qreal size) const;
    Q_INVOKABLE bool setBrushOpacity(qreal opacityPercent) const;
    Q_INVOKABLE bool setForegroundColor(const QString &colorName) const;
    Q_INVOKABLE bool setEraserMode(bool enabled) const;
    Q_INVOKABLE bool setActiveTool(const QString &toolName) const;
    Q_INVOKABLE bool openRecentDocument(int index) const;
    Q_INVOKABLE bool saveDocument(bool exportImage) const;
    Q_INVOKABLE void showHomeScreen() const;

    Q_INVOKABLE QVariantList brushPresets(const QString &filter = QString()) const;
    Q_INVOKABLE bool activateBrushPreset(int resourceId) const;
    Q_INVOKABLE QVariantList layers() const;
    Q_INVOKABLE bool activateLayer(qulonglong id) const;
    Q_INVOKABLE bool setLayerVisible(qulonglong id, bool visible) const;
    Q_INVOKABLE bool renameLayer(qulonglong id, const QString &name) const;
    Q_INVOKABLE bool removeLayer(qulonglong id) const;
    Q_INVOKABLE bool addPaintLayer() const;

Q_SIGNALS:
    void documentStateChanged();

private:
    KisMainWindow *m_mainWindow {nullptr};
};

#endif // KIS_MOBILE_BRIDGE_H
