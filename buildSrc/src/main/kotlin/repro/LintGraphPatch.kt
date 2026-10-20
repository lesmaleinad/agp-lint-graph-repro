package repro

import net.bytebuddy.agent.ByteBuddyAgent
import net.bytebuddy.agent.builder.AgentBuilder.RedefinitionStrategy.RETRANSFORMATION
import org.gradle.api.invocation.Gradle
import net.bytebuddy.agent.builder.AgentBuilder
import net.bytebuddy.asm.Advice
import net.bytebuddy.description.method.MethodDescription
import net.bytebuddy.matcher.ElementMatchers.*

object LintGraphPatch {
    @JvmStatic
    fun install(gradle: Gradle) {
        val instrumentation = ByteBuddyAgent.install()
        val transformer = AgentBuilder.Default()
            .disableClassFormatChanges()
            .with(RETRANSFORMATION)
            .with(AgentBuilder.Listener.StreamWriting.toSystemError().withErrorsOnly())
            .type(named("com.android.build.gradle.internal.lint.LintTaskManager\$createLintTasks\$11"))
            .transform { builder, _, _, _, _ ->
                builder.visit(Advice.to(EmptyMapGuard::class.java).on(
                    named<MethodDescription>("execute")
                        .and(takesArguments(1))
                        .and(takesArgument(0, named("org.gradle.api.execution.TaskExecutionGraph")))
                ))
            }
            .installOn(instrumentation)
        gradle.buildFinished { transformer.reset(instrumentation, RETRANSFORMATION) }
    }

    object EmptyMapGuard {
        @JvmStatic
        @Advice.OnMethodEnter(skipOn = Advice.OnNonDefaultValue::class)
        fun skip(@Advice.FieldValue("\$variantLintTaskToLintVitalTask") tasks: Map<*, *>): Boolean {
            val skip = java.lang.Boolean.getBoolean("repro.lintEmptyMapGuard") && tasks.isEmpty()
            if (java.lang.Boolean.getBoolean("repro.showLintState")) {
                System.out.println("LINT_MAP entries=${tasks.size} skipped=$skip")
            }
            return skip
        }
    }
}
