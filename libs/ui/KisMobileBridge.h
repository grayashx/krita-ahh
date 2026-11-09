/*
 * SPDX-FileCopyrightText: 2026 Krita Mobile project contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef KIS_MOBILE_BRIDGE_H
#define KIS_MOBILE_BRIDGE_H

#include <QObject>
#include <QString>

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

Q_SIGNALS:
    void documentStateChanged();

private:
    KisMainWindow *m_mainWindow {nullptr};
};

#endif // KIS_MOBILE_BRIDGE_H
