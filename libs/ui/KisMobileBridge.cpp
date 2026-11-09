/*
 * SPDX-FileCopyrightText: 2026 Krita Mobile project contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "KisMobileBridge.h"

#include "KisMainWindow.h"
#include "KisView.h"
#include "KisViewManager.h"
#include <KoToolManager.h>
#include "kis_canvas_resource_provider.h"

#include <KoColor.h>

#include <QAction>
#include <QColor>
#include <QMap>
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

bool KisMobileBridge::setBrushSize(qreal size) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setSize(qBound<qreal>(0.01, size, 100000.0));
    return true;
}

bool KisMobileBridge::setBrushOpacity(qreal opacityPercent) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setOpacity(qBound<qreal>(0.0, opacityPercent, 100.0) / 100.0);
    return true;
}

bool KisMobileBridge::setForegroundColor(const QString &colorName) const
{
    if (!hasActiveDocument()) return false;
    const QColor color(colorName);
    if (!color.isValid()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    KoColor foreground = resources->fgColor();
    foreground.fromQColor(color);
    resources->setFGColor(foreground);
    return true;
}

bool KisMobileBridge::setEraserMode(bool enabled) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setEraserMode(enabled);
    return true;
}


bool KisMobileBridge::setActiveTool(const QString &toolName) const
{
    if (!hasActiveDocument() || !m_mainWindow->viewManager()) return false;

    // Keep the QML surface label-based. Only expose tools that are known to
    // exist in Krita's registered tool factories.
    static const QMap<QString, QString> toolIds {
        {QStringLiteral("Brush"), QStringLiteral("KritaShape/KisToolBrush")},
        {QStringLiteral("Picker"), QStringLiteral("KritaSelected/KisToolColorSampler")},
        {QStringLiteral("Shape"), QStringLiteral("KritaShape/KisToolRectangle")},
        {QStringLiteral("Text"), QStringLiteral("SvgTextTool")},
        {QStringLiteral("Move"), QStringLiteral("KritaTransform/KisToolMove")}
    };

    const auto it = toolIds.constFind(toolName);
    if (it == toolIds.cend()) return false;

    KoToolManager *toolManager = m_mainWindow->viewManager()->toolManager();
    if (!toolManager) return false;

    toolManager->switchToolRequested(it.value());
    return toolManager->activeToolId() == it.value();
}
