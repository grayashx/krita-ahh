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
class KisCanvasResourceProvider;

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
    Q_INVOKABLE bool setBackgroundColor(const QString &colorName) const;
    Q_INVOKABLE QString foregroundColor() const;
    Q_INVOKABLE QString backgroundColor() const;
    Q_INVOKABLE QVariantList recentColors() const;
    Q_INVOKABLE bool swapColors() const;
    Q_INVOKABLE bool setEraserMode(bool enabled) const;
    Q_INVOKABLE bool setActiveTool(const QString &toolName) const;
    Q_INVOKABLE bool openRecentDocument(int index) const;
    Q_INVOKABLE bool saveDocument(bool exportImage) const;
    Q_INVOKABLE void showHomeScreen() const;

    Q_INVOKABLE QVariantList brushTags() const;
    Q_INVOKABLE QVariantList brushPresets(const QString &filter = QString(), const QString &tagUrl = QString()) const;
    Q_INVOKABLE bool activateBrushPreset(int resourceId) const;
    Q_INVOKABLE bool setBrushPresetFavorite(int resourceId, bool favorite) const;
    Q_INVOKABLE bool hideBrushPreset(int resourceId) const;
    Q_INVOKABLE QVariantList layers() const;
    Q_INVOKABLE bool activateLayer(const QString &id) const;
    Q_INVOKABLE bool setLayerVisible(const QString &id, bool visible) const;
    Q_INVOKABLE bool setLayerOpacity(const QString &id, qreal opacityPercent) const;
    Q_INVOKABLE QVariantList blendModes(const QString &id) const;
    Q_INVOKABLE bool setLayerBlendMode(const QString &id, const QString &compositeOpId) const;
    Q_INVOKABLE bool setLayerLocked(const QString &id, bool locked) const;
    Q_INVOKABLE bool setLayerAlphaLocked(const QString &id, bool locked) const;
    Q_INVOKABLE bool setLayerInheritAlpha(const QString &id, bool enabled) const;
    Q_INVOKABLE bool setGroupPassThrough(const QString &id, bool enabled) const;
    Q_INVOKABLE bool setLayerSelected(const QString &id, bool selected) const;
    Q_INVOKABLE bool addLayerMask(const QString &id, const QString &maskType) const;
    Q_INVOKABLE bool createGroup() const;
    Q_INVOKABLE bool createClippingGroup() const;
    Q_INVOKABLE bool ungroup() const;
    Q_INVOKABLE bool raiseLayer(const QString &id) const;
    Q_INVOKABLE bool lowerLayer(const QString &id) const;
    Q_INVOKABLE bool renameLayer(const QString &id, const QString &name) const;
    Q_INVOKABLE bool removeLayer(const QString &id) const;
    Q_INVOKABLE bool addPaintLayer() const;

Q_SIGNALS:
    void documentStateChanged();
    void colorsChanged();

private:
    void connectColorResourceSignals();

    KisMainWindow *m_mainWindow {nullptr};
    KisCanvasResourceProvider *m_connectedColorResources {nullptr};
};

#endif // KIS_MOBILE_BRIDGE_H
