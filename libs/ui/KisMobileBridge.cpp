/*
 * SPDX-FileCopyrightText: 2026 Krita Mobile project contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "KisMobileBridge.h"

#include "KisMainWindow.h"
#include "KisView.h"

#include <QAction>
#include <kactioncollection.h>

KisMobileBridge::KisMobileBridge(KisMainWindow *mainWindow)
    : QObject(mainWindow)
    , m_mainWindow(mainWindow)
{
    if (m_mainWindow) {
        connect(m_mainWindow, &KisMainWindow::activeViewChanged,
                this, &KisMobileBridge::documentStateChanged);
        connect(m_mainWindow, &KisMainWindow::loadCompleted,
                this, &KisMobileBridge::documentStateChanged);
    }
}

bool KisMobileBridge::triggerAction(const QString &actionId) const
{
    if (!m_mainWindow || actionId.isEmpty()) {
        return false;
    }

    QAction *action = m_mainWindow->actionCollection()->action(actionId);
    if (!action || !action->isEnabled()) {
        return false;
    }

    action->trigger();
    return true;
}

bool KisMobileBridge::isActionEnabled(const QString &actionId) const
{
    if (!m_mainWindow || actionId.isEmpty()) {
        return false;
    }

    QAction *action = m_mainWindow->actionCollection()->action(actionId);
    return action && action->isEnabled();
}

bool KisMobileBridge::hasActiveDocument() const
{
    return m_mainWindow && m_mainWindow->activeView()
        && m_mainWindow->activeView()->document();
}
